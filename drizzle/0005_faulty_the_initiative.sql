CREATE TABLE `courier_events` (
	`id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`courier_id` text NOT NULL,
	`consignment` text NOT NULL,
	`raw_status` text NOT NULL,
	`mapped_status` text NOT NULL,
	`source` text DEFAULT 'Manual' NOT NULL,
	`reference` text DEFAULT '' NOT NULL,
	`at` text NOT NULL,
	`actor` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `packing_checks` (
	`id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`item_id` text NOT NULL,
	`checked` integer NOT NULL,
	`actor` text NOT NULL,
	`at` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`item_id`) REFERENCES `order_items`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `packing_checks_item_id_unique` ON `packing_checks` (`item_id`);--> statement-breakpoint
CREATE TABLE `payments` (
	`id` text PRIMARY KEY NOT NULL,
	`request_key` text NOT NULL,
	`order_id` text NOT NULL,
	`kind` text NOT NULL,
	`amount` integer NOT NULL,
	`reference` text DEFAULT '' NOT NULL,
	`at` text NOT NULL,
	`actor` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `payments_request_key_unique` ON `payments` (`request_key`);--> statement-breakpoint
CREATE TABLE `settlements` (
	`order_id` text PRIMARY KEY NOT NULL,
	`collected` integer NOT NULL,
	`delivery_fee` integer NOT NULL,
	`cod_fee` integer NOT NULL,
	`return_fee` integer NOT NULL,
	`remitted` integer NOT NULL,
	`reference` text DEFAULT '' NOT NULL,
	`at` text NOT NULL,
	`actor` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
ALTER TABLE `orders` ADD `followup_at` text;--> statement-breakpoint
ALTER TABLE `orders` ADD `followup_reason` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `followup_note` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `followup_done` integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `return_reason` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `parent_id` text;--> statement-breakpoint
ALTER TABLE `products` ADD `variant_label` text DEFAULT '' NOT NULL;--> statement-breakpoint
CREATE TRIGGER validate_payment BEFORE INSERT ON payments BEGIN
 SELECT CASE WHEN NEW.amount<1 OR NEW.kind NOT IN ('Advance','Collection','Refund') THEN RAISE(ABORT,'invalid payment') END;
 SELECT CASE WHEN NEW.kind='Refund' AND NEW.amount>COALESCE((SELECT SUM(CASE WHEN kind='Refund' THEN -amount ELSE amount END) FROM payments WHERE order_id=NEW.order_id),0) THEN RAISE(ABORT,'refund exceeds receipts') END;
 SELECT CASE WHEN NEW.kind<>'Refund' AND NEW.amount+COALESCE((SELECT SUM(CASE WHEN kind='Refund' THEN -amount ELSE amount END) FROM payments WHERE order_id=NEW.order_id),0)>(SELECT total FROM orders WHERE id=NEW.order_id) THEN RAISE(ABORT,'payment exceeds total') END;
END;
--> statement-breakpoint
CREATE INDEX courier_events_order_at ON courier_events(order_id,at);
--> statement-breakpoint
CREATE INDEX payments_order ON payments(order_id);
--> statement-breakpoint
CREATE INDEX orders_followup ON orders(followup_done,followup_at);
--> statement-breakpoint
CREATE TRIGGER require_packing BEFORE UPDATE OF status ON orders WHEN NEW.status IN ('Packed','Dispatched') AND NEW.status<>OLD.status BEGIN
 SELECT CASE WHEN EXISTS(SELECT 1 FROM order_items i LEFT JOIN packing_checks p ON p.item_id=i.id WHERE i.order_id=NEW.id AND COALESCE(p.checked,0)=0) THEN RAISE(ABORT,'packing checklist incomplete') END;
END;
--> statement-breakpoint
CREATE TRIGGER require_return_reason BEFORE UPDATE OF status ON orders WHEN NEW.status='Returned' AND trim(NEW.return_reason)='' BEGIN SELECT RAISE(ABORT,'return reason required'); END;
--> statement-breakpoint
CREATE TRIGGER packing_insert_guard BEFORE INSERT ON packing_checks WHEN (SELECT status FROM orders WHERE id=NEW.order_id) NOT IN ('Confirmed','Processing','Packed') BEGIN SELECT RAISE(ABORT,'packing closed'); END;
--> statement-breakpoint
CREATE TRIGGER packing_update_guard BEFORE UPDATE ON packing_checks WHEN (SELECT status FROM orders WHERE id=NEW.order_id) NOT IN ('Confirmed','Processing','Packed') BEGIN SELECT RAISE(ABORT,'packing closed'); END;
