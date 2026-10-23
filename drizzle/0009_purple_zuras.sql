CREATE TABLE `return_cases` (
	`order_id` text PRIMARY KEY NOT NULL,
	`courier_id` text,
	`consignment` text DEFAULT '' NOT NULL,
	`legacy` integer DEFAULT 0 NOT NULL,
	`created_at` text NOT NULL,
	`received_at` text,
	`received_by` text,
	`kind` text,
	`reference` text DEFAULT '' NOT NULL,
	`note` text DEFAULT '' NOT NULL,
	`evidence` text DEFAULT '[]' NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `return_issues` (
	`id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`item_id` text NOT NULL,
	`kind` text NOT NULL,
	`qty` integer NOT NULL,
	`status` text DEFAULT 'Open' NOT NULL,
	`requested` integer NOT NULL,
	`paid` integer DEFAULT 0 NOT NULL,
	`recovered` integer DEFAULT 0 NOT NULL,
	`reference` text DEFAULT '' NOT NULL,
	`note` text DEFAULT '' NOT NULL,
	`updated_at` text NOT NULL,
	`updated_by` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `return_cases`(`order_id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`item_id`) REFERENCES `order_items`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `return_lines` (
	`item_id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`good` integer NOT NULL,
	`damaged` integer NOT NULL,
	`missing` integer NOT NULL,
	FOREIGN KEY (`item_id`) REFERENCES `order_items`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`order_id`) REFERENCES `return_cases`(`order_id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
DROP TRIGGER restock_order;
--> statement-breakpoint
CREATE TRIGGER restock_cancelled AFTER UPDATE OF status ON orders WHEN NEW.status='Cancelled' AND OLD.status NOT IN ('Cancelled','Returned') BEGIN
 UPDATE products SET stock=stock+(SELECT SUM(qty) FROM order_items WHERE order_id=NEW.id AND product_id=products.id) WHERE id IN (SELECT product_id FROM order_items WHERE order_id=NEW.id);
END;
--> statement-breakpoint
CREATE TRIGGER create_return_case AFTER UPDATE OF status ON orders WHEN NEW.status='Returned' AND OLD.status<>'Returned' BEGIN
 INSERT INTO return_cases(order_id,courier_id,consignment,created_at) VALUES(NEW.id,NEW.courier_id,NEW.consignment,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
END;
--> statement-breakpoint
CREATE TRIGGER receive_return_once BEFORE UPDATE OF received_at ON return_cases WHEN OLD.received_at IS NOT NULL BEGIN SELECT RAISE(ABORT,'return already inspected'); END;
--> statement-breakpoint
CREATE TRIGGER validate_return_line BEFORE INSERT ON return_lines BEGIN
 SELECT CASE WHEN NEW.good<0 OR NEW.damaged<0 OR NEW.missing<0 OR NEW.good+NEW.damaged+NEW.missing<>(SELECT qty FROM order_items WHERE id=NEW.item_id AND order_id=NEW.order_id) OR NOT EXISTS(SELECT 1 FROM order_items WHERE id=NEW.item_id AND order_id=NEW.order_id) OR NOT EXISTS(SELECT 1 FROM return_cases WHERE order_id=NEW.order_id AND received_at IS NOT NULL) THEN RAISE(ABORT,'invalid return quantities') END;
END;
--> statement-breakpoint
CREATE TRIGGER restock_received_return AFTER INSERT ON return_lines WHEN (SELECT legacy FROM return_cases WHERE order_id=NEW.order_id)=0 BEGIN
 UPDATE products SET stock=stock+NEW.good WHERE id=(SELECT product_id FROM order_items WHERE id=NEW.item_id);
END;
--> statement-breakpoint
CREATE TRIGGER return_line_immutable BEFORE UPDATE ON return_lines BEGIN SELECT RAISE(ABORT,'inspection quantities are immutable'); END;
--> statement-breakpoint
CREATE TRIGGER validate_issue_recovery BEFORE UPDATE ON return_issues BEGIN
 SELECT CASE WHEN NEW.recovered<OLD.recovered OR NEW.recovered>NEW.qty OR (NEW.recovered<>OLD.recovered AND NEW.status<>'Closed') OR (OLD.status='Closed' AND (NEW.recovered<>OLD.recovered OR NEW.status<>OLD.status)) THEN RAISE(ABORT,'invalid recovery or closed inquiry') END;
END;
--> statement-breakpoint
CREATE TRIGGER restock_recovered_return AFTER UPDATE OF recovered ON return_issues WHEN NEW.recovered>OLD.recovered AND (SELECT legacy FROM return_cases WHERE order_id=NEW.order_id)=0 BEGIN
 UPDATE products SET stock=stock+NEW.recovered-OLD.recovered WHERE id=(SELECT product_id FROM order_items WHERE id=NEW.item_id);
END;
--> statement-breakpoint
CREATE INDEX return_issues_queue ON return_issues(status,updated_at);
