CREATE TABLE `categories` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`slug` text NOT NULL,
	`description` text DEFAULT '' NOT NULL,
	`image` text DEFAULT '' NOT NULL,
	`sort_order` integer DEFAULT 0 NOT NULL,
	`active` integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `categories_name_unique` ON `categories` (`name`);--> statement-breakpoint
CREATE UNIQUE INDEX `categories_slug_unique` ON `categories` (`slug`);--> statement-breakpoint
ALTER TABLE `products` ADD `slug` text;--> statement-breakpoint
ALTER TABLE `products` ADD `short_description` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `images` text DEFAULT '[]' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `material` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `dimensions` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `care` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `tags` text DEFAULT '[]' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `compare_at` integer;--> statement-breakpoint
CREATE UNIQUE INDEX `products_slug_unique` ON `products` (`slug`);