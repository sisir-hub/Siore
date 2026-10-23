CREATE TABLE `order_history` (
	`id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`status` text NOT NULL,
	`at` text NOT NULL,
	`actor` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `order_items` (
	`id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`product_id` text NOT NULL,
	`name` text NOT NULL,
	`price` integer NOT NULL,
	`qty` integer NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `orders` (
	`id` text PRIMARY KEY NOT NULL,
	`request_key` text NOT NULL,
	`fingerprint` text NOT NULL,
	`name` text NOT NULL,
	`phone` text NOT NULL,
	`address` text NOT NULL,
	`zone` text NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`source` text DEFAULT 'Website' NOT NULL,
	`subtotal` integer NOT NULL,
	`shipping` integer NOT NULL,
	`total` integer NOT NULL,
	`status` text DEFAULT 'Pending' NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `orders_request_key_unique` ON `orders` (`request_key`);--> statement-breakpoint
CREATE TABLE `products` (
	`id` text PRIMARY KEY NOT NULL,
	`sku` text NOT NULL,
	`name` text NOT NULL,
	`description` text DEFAULT '' NOT NULL,
	`price` integer NOT NULL,
	`stock` integer DEFAULT 0 NOT NULL,
	`category` text DEFAULT 'Bracelets' NOT NULL,
	`image` text DEFAULT '' NOT NULL,
	`status` text DEFAULT 'draft' NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `products_sku_unique` ON `products` (`sku`);--> statement-breakpoint
CREATE TABLE `settings` (
	`key` text PRIMARY KEY NOT NULL,
	`value` integer NOT NULL
);
--> statement-breakpoint
CREATE TRIGGER validate_product_insert BEFORE INSERT ON products WHEN NEW.stock < 0 OR NEW.price < 1 BEGIN SELECT RAISE(ABORT,'invalid product'); END;
--> statement-breakpoint
CREATE TRIGGER validate_product_update BEFORE UPDATE ON products WHEN NEW.stock < 0 OR NEW.price < 1 BEGIN SELECT RAISE(ABORT,'invalid product'); END;
--> statement-breakpoint
CREATE TRIGGER reserve_stock BEFORE INSERT ON order_items BEGIN
 SELECT CASE WHEN NEW.qty < 1 OR NOT EXISTS(SELECT 1 FROM products WHERE id=NEW.product_id AND status='active' AND stock>=NEW.qty AND price=NEW.price) THEN RAISE(ABORT,'insufficient stock or changed price') END;
 UPDATE products SET stock=stock-NEW.qty WHERE id=NEW.product_id;
END;
--> statement-breakpoint
CREATE TRIGGER restock_order AFTER UPDATE OF status ON orders WHEN NEW.status IN ('Cancelled','Returned') AND OLD.status NOT IN ('Cancelled','Returned') BEGIN
 UPDATE products SET stock=stock+(SELECT SUM(qty) FROM order_items WHERE order_id=NEW.id AND product_id=products.id) WHERE id IN (SELECT product_id FROM order_items WHERE order_id=NEW.id);
END;
--> statement-breakpoint
CREATE TRIGGER record_order_status AFTER UPDATE OF status ON orders WHEN NEW.status<>OLD.status BEGIN
 INSERT INTO order_history(id,order_id,status,at,actor) VALUES(lower(hex(randomblob(16))),NEW.id,NEW.status,strftime('%Y-%m-%dT%H:%M:%fZ','now'),'Owner');
END;
--> statement-breakpoint
CREATE INDEX orders_created_at ON orders(created_at);
--> statement-breakpoint
CREATE INDEX items_order_id ON order_items(order_id);
