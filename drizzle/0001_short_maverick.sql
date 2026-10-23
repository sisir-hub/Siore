CREATE TABLE `audit_log` (
	`id` text PRIMARY KEY NOT NULL,
	`actor` text NOT NULL,
	`action` text NOT NULL,
	`target` text NOT NULL,
	`at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `couriers` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`tracking_template` text DEFAULT '' NOT NULL,
	`active` integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE TABLE `staff` (
	`id` text PRIMARY KEY NOT NULL,
	`email` text NOT NULL,
	`user_id` text,
	`name` text NOT NULL,
	`role` text NOT NULL,
	`permissions` text NOT NULL,
	`active` integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `staff_email_unique` ON `staff` (`email`);--> statement-breakpoint
ALTER TABLE `orders` ADD `created_by` text;--> statement-breakpoint
ALTER TABLE `orders` ADD `courier_id` text;--> statement-breakpoint
ALTER TABLE `orders` ADD `consignment` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `tracking_url` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `updated_at` text;