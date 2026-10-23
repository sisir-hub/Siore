CREATE TABLE `return_issue_history` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`issue_id` text NOT NULL,
	`status` text NOT NULL,
	`requested` integer NOT NULL,
	`paid` integer NOT NULL,
	`recovered` integer NOT NULL,
	`reference` text NOT NULL,
	`note` text NOT NULL,
	`at` text NOT NULL,
	`actor` text NOT NULL,
	FOREIGN KEY (`issue_id`) REFERENCES `return_issues`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TRIGGER log_return_issue_insert AFTER INSERT ON return_issues BEGIN
 INSERT INTO return_issue_history(issue_id,status,requested,paid,recovered,reference,note,at,actor) VALUES(NEW.id,NEW.status,NEW.requested,NEW.paid,NEW.recovered,NEW.reference,NEW.note,NEW.updated_at,NEW.updated_by);
END;
--> statement-breakpoint
CREATE TRIGGER log_return_issue_update AFTER UPDATE ON return_issues BEGIN
 INSERT INTO return_issue_history(issue_id,status,requested,paid,recovered,reference,note,at,actor) VALUES(NEW.id,NEW.status,NEW.requested,NEW.paid,NEW.recovered,NEW.reference,NEW.note,NEW.updated_at,NEW.updated_by);
END;
