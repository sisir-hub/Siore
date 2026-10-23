CREATE TABLE `order_numbers` (
	`number` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`order_id` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `order_numbers_order_id_unique` ON `order_numbers` (`order_id`);--> statement-breakpoint
ALTER TABLE `orders` ADD `weight_grams` integer;--> statement-breakpoint
CREATE TRIGGER dispatch_weight_guard BEFORE UPDATE OF status ON orders WHEN NEW.status='Dispatched' AND COALESCE(NEW.weight_grams,0)<=0 BEGIN SELECT RAISE(ABORT,'parcel weight required'); END;
