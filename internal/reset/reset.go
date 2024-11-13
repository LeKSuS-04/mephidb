package reset

import (
	"context"
	"errors"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

const maxRetries = 3

var tableNames = []string{
	"users",
	"user_addresses",
	"user_cards",
	"orders",
	"orders_composition",
	"payments",
	"couriers",
	"dishes",
	"commodities",
	"categories",
	"categories_to_targets",
	"suppliers",
	// "discounts",
}

func Reset(pg *pgxpool.Pool) error {
	errs := make(chan error, len(tableNames))
	for table := range tableNames {
		go func() {
			var err error
			for range maxRetries {
				if err = resetTable(pg, tableNames[table]); err == nil {
					break
				}
			}
			errs <- err
		}()
	}

	var err error
	for range tableNames {
		err = errors.Join(err, <-errs)
	}
	return err
}

func resetTable(pg *pgxpool.Pool, tableName string) error {
	_, err := pg.Exec(context.Background(), "DELETE FROM "+tableName)
	if err != nil {
		return fmt.Errorf("reset table %q: %w", tableName, err)
	}
	log.Printf("Successfully reset table %q", tableName)
	return nil
}
