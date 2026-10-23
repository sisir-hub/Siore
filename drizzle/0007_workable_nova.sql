ALTER TABLE `orders` ADD `booking_status` text DEFAULT 'Not sent' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `booking_source` text DEFAULT 'None' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `courier_payment_status` text DEFAULT 'Not synced' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `courier_updated_at` text;--> statement-breakpoint
ALTER TABLE `orders` ADD `courier_payment_updated_at` text;