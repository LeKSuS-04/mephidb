package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/urfave/cli/v2"

	"github.com/LeKSuS-04/mephi-db/internal/db/queries"
	"github.com/LeKSuS-04/mephi-db/internal/gen"
	"github.com/LeKSuS-04/mephi-db/internal/reset"
)

func main() {
	app := &cli.App{
		Name:  "ctrl",
		Usage: "Utility for controlling your database",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:    "address",
				Aliases: []string{"a"},
				Usage:   "Address of postgres database",
				Value:   "localhost:5432",
			},
			&cli.StringFlag{
				Name:    "user",
				Aliases: []string{"u"},
				Usage:   "User to connect to postgres as",
				Value:   "postgres",
			},
			&cli.StringFlag{
				Name:     "password",
				Aliases:  []string{"p"},
				Usage:    "Password for the postgres user",
				Required: true,
			},
			&cli.StringFlag{
				Name:  "db",
				Usage: "Nasme of the database",
				Value: "postgres",
			},
		},
		Commands: []*cli.Command{
			{
				Name:    "generate",
				Aliases: []string{"gen"},
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name: "reset",
						Usage: "Resets tables to initial states before generating " +
							"dummy data",
						Value: false,
					},
				},
				Usage: "Generate dummy data",
				Action: func(ctx *cli.Context) error {
					pool, err := createPostgresConnectionPool(ctx)
					if err != nil {
						return fmt.Errorf("create postgres connection pool: %w", err)
					}

					if ctx.Bool("reset") {
						if err := reset.Reset(pool); err != nil {
							return fmt.Errorf("reset db: %w", err)
						}
					}

					q := queries.New(pool)
					if err := gen.Generate(q); err != nil {
						return fmt.Errorf("generate dummy data: %w", err)
					}

					return nil
				},
			},
			{
				Name:  "reset",
				Usage: "Resets tables to initial states",
				Action: func(ctx *cli.Context) error {
					pool, err := createPostgresConnectionPool(ctx)
					if err != nil {
						return fmt.Errorf("create postgres connection pool: %w", err)
					}

					if err := reset.Reset(pool); err != nil {
						return fmt.Errorf("reset db: %w", err)
					}

					return nil
				},
			},
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err.Error())
	}
}

func createPostgresConnectionPool(ctx *cli.Context) (*pgxpool.Pool, error) {
	user := ctx.String("user")
	password := ctx.String("password")
	address := ctx.String("address")
	db := ctx.String("db")
	connectionUri := fmt.Sprintf("postgresql://%s:%s@%s/%s", user, password, address, db)
	pool, err := pgxpool.New(context.Background(), connectionUri)
	if err != nil {
		return nil, err
	}
	return pool, nil
}
