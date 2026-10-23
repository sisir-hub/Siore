CREATE TABLE `courier_credentials` (
	`id` text PRIMARY KEY NOT NULL,
	`courier_id` text NOT NULL,
	`environment` text NOT NULL,
	`encrypted` text NOT NULL,
	`updated_at` text NOT NULL,
	FOREIGN KEY (`courier_id`) REFERENCES `couriers`(`id`) ON UPDATE no action ON DELETE no action
);
