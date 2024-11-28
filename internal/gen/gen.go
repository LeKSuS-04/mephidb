package gen

import (
	"context"
	"errors"
	"fmt"
	"log"
	"math/rand/v2"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/LeKSuS-04/mephi-db/internal/db/queries"
	"github.com/LeKSuS-04/mephi-db/pkg/future"
	"github.com/LeKSuS-04/mephi-db/pkg/launcher"
)

const (
	AmountAmplifier = 1_000

	UserCount           = 50 * AmountAmplifier
	CardsPerUserMin     = 1
	CardsPerUserMax     = 5
	AddressesPerUserMin = 1
	AddressesPerUserMax = 10

	CourierCount = 1 * AmountAmplifier

	OrderCount       = 300 * AmountAmplifier
	MinItemsPerOrder = 1
	MaxItemsPerOrder = 10

	SupplierCount       = max(5, AmountAmplifier/10)
	MinItemsPerSupplier = 3
	MaxItemsPerSupplier = 10

	DiscountCount = max(5, AmountAmplifier/2)
)

func Generate(q *queries.Queries) error {
	launch := launcher.New()

	usersFut := future.New[[]int32]()
	userCardsFut := future.New[[]int32]()
	couriersFut := future.New[[]int32]()
	paymentsFut := future.New[[]int32]()
	ordersFut := future.New[[]int32]()
	suppliersFut := future.New[[]int32]()
	dishesFut := future.New[[]int32]()
	commoditiesFut := future.New[[]int32]()
	categoriesFut := future.New[[]int32]()
	discountsFut := future.New[[]int32]()

	launch.Go(func() error {
		userIDs, err := createUsers(q)
		if err != nil {
			usersFut.Cancel()
			return err
		}
		usersFut.Set(userIDs)
		return err
	})

	launch.Go(func() (err error) {
		defer func() {
			if err != nil {
				userCardsFut.Cancel()
			}
		}()
		userIDs, err := usersFut.Get()
		if err != nil {
			return errors.New("users not created")
		}
		userCardIDs, err := createCards(q, userIDs)
		if err != nil {
			return err
		}
		userCardsFut.Set(userCardIDs)
		return nil
	})

	launch.Go(func() error {
		userIDs, err := usersFut.Get()
		if err != nil {
			return errors.New("users not created")
		}
		return createAddresses(q, userIDs)
	})

	launch.Go(func() error {
		courierIDs, err := createCouriers(q)
		if err != nil {
			couriersFut.Cancel()
			return err
		}
		couriersFut.Set(courierIDs)
		return nil
	})

	launch.Go(func() (err error) {
		defer func() {
			if err != nil {
				paymentsFut.Cancel()
			}
		}()
		userCardIDs, err := userCardsFut.Get()
		if err != nil {
			return errors.New("cards not created")
		}
		paymentIDs, err := createPayments(q, userCardIDs)
		if err != nil {
			paymentsFut.Cancel()
			return err
		}
		paymentsFut.Set(paymentIDs)
		return nil
	})

	launch.Go(func() (err error) {
		defer func() {
			if err != nil {
				ordersFut.Cancel()
			}
		}()

		userIDs, err := usersFut.Get()
		if err != nil {
			return errors.New("users not created")
		}
		courierIDs, err := couriersFut.Get()
		if err != nil {
			return errors.New("couriers not created")
		}
		paymentIDs, err := paymentsFut.Get()
		if err != nil {
			return errors.New("payments not created")
		}
		orderIDs, err := createOrders(q, userIDs, courierIDs, paymentIDs)
		if err != nil {
			return err
		}
		ordersFut.Set(orderIDs)
		return err
	})

	launch.Go(func() error {
		supplierIDs, err := createSuppliers(q)
		if err != nil {
			suppliersFut.Cancel()
			return err
		}
		suppliersFut.Set(supplierIDs)
		return nil
	})

	launch.Go(func() (err error) {
		defer func() {
			if err != nil {
				dishesFut.Cancel()
			}
		}()
		supplierIDs, err := suppliersFut.Get()
		if err != nil {
			return errors.New("suppliers not created")
		}
		dishIDs, err := createDishes(q, supplierIDs)
		if err != nil {
			return err
		}
		dishesFut.Set(dishIDs)
		return nil
	})

	launch.Go(func() (err error) {
		defer func() {
			if err != nil {
				commoditiesFut.Cancel()
			}
		}()
		supplierIDs, err := suppliersFut.Get()
		if err != nil {
			return errors.New("suppliers not created")
		}
		commodityIDs, err := createCommodities(q, supplierIDs)
		if err != nil {
			return err
		}
		commoditiesFut.Set(commodityIDs)
		return nil
	})

	launch.Go(func() error {
		orderIDs, err := ordersFut.Get()
		if err != nil {
			return errors.New("orders not created")
		}
		dishIDs, err := dishesFut.Get()
		if err != nil {
			return errors.New("dishes not created")
		}
		commodityIDs, err := commoditiesFut.Get()
		if err != nil {
			return errors.New("commodities not created")
		}
		return createOrderCompositions(q, orderIDs, dishIDs, commodityIDs)
	})

	launch.Go(func() error {
		categoryIDs, err := createCategories(q)
		if err != nil {
			categoriesFut.Cancel()
			return err
		}
		categoriesFut.Set(categoryIDs)
		return nil
	})

	launch.Go(func() error {
		categoryIDs, err := categoriesFut.Get()
		if err != nil {
			return errors.New("categories not created")
		}
		dishIDs, err := dishesFut.Get()
		if err != nil {
			return errors.New("dishes not created")
		}
		commodityIDs, err := commoditiesFut.Get()
		if err != nil {
			return errors.New("commodities not created")
		}
		return createCategoriesToTargets(q, categoryIDs, dishIDs, commodityIDs)
	})

	launch.Go(func() error {
		discountIDs, err := createDiscounts(q)
		if err != nil {
			discountsFut.Cancel()
			return err
		}
		discountsFut.Set(discountIDs)
		return nil
	})

	launch.Go(func() error {
		discountIDs, err := discountsFut.Get()
		if err != nil {
			return errors.New("discounts not created")
		}
		dishIDs, err := dishesFut.Get()
		if err != nil {
			return errors.New("dishes not created")
		}
		commodityIDs, err := commoditiesFut.Get()
		if err != nil {
			return errors.New("commodities not created")
		}
		return createDiscountsToTargets(q, discountIDs, dishIDs, commodityIDs)
	})

	return launch.Wait()
}

func createUsers(q *queries.Queries) ([]int32, error) {
	log.Printf("Generating %d users", UserCount)
	users := make([]queries.CreateUsersParams, 0, UserCount)
	for range UserCount {
		users = append(users, randomUser())
	}
	log.Printf("Creating %d users", len(users))
	if _, err := q.CreateUsers(context.Background(), users); err != nil {
		return nil, fmt.Errorf("create users: %w", err)
	}

	log.Print("Selecting user ids")
	userIDs, err := q.SelectUserIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select user ids")
	}

	return userIDs, nil
}

func createCards(q *queries.Queries, userIDs []int32) ([]int32, error) {
	log.Print("Generating cards")
	cards := make([]queries.CreateUserCardsParams, 0, len(userIDs)*CardsPerUserMax)
	totalCards := 0
	for _, userID := range userIDs {
		userCardCount := rand.IntN(CardsPerUserMax-CardsPerUserMin) + CardsPerUserMin
		totalCards += userCardCount
		for i := 0; i < userCardCount; i++ {
			cards = append(cards, randomCard(userID))
		}
	}

	log.Printf("Creating %d cards", totalCards)
	if _, err := q.CreateUserCards(context.Background(), cards[:totalCards]); err != nil {
		return nil, fmt.Errorf("create cards: %w", err)
	}

	log.Print("Selecting card ids")
	cardIDs, err := q.SelectUserCardIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select card ids: %w", err)
	}

	return cardIDs, nil
}

func createAddresses(q *queries.Queries, userIDs []int32) error {
	log.Print("Generating addresses")
	cards := make([]queries.CreateUserAddressesParams, 0, len(userIDs)*AddressesPerUserMax)
	totalAddresses := 0
	for _, userID := range userIDs {
		userAddressCount := rand.IntN(AddressesPerUserMax-AddressesPerUserMin) + AddressesPerUserMin
		totalAddresses += userAddressCount
		for i := 0; i < userAddressCount; i++ {
			cards = append(cards, randomAddress(userID))
		}
	}

	log.Printf("Creating %d addresses", totalAddresses)
	if _, err := q.CreateUserAddresses(context.Background(), cards[:totalAddresses]); err != nil {
		return fmt.Errorf("create address: %w", err)
	}

	return nil
}

func createCouriers(q *queries.Queries) ([]int32, error) {
	log.Printf("Generating %d couriers", CourierCount)
	couriers := make([]queries.CreateCourieresParams, 0, CourierCount)
	for range CourierCount {
		couriers = append(couriers, randomCourier())
	}

	log.Printf("Creating %d couriers", len(couriers))
	if _, err := q.CreateCourieres(context.Background(), couriers); err != nil {
		return nil, fmt.Errorf("create couriers: %w", err)
	}

	log.Print("Selecting courier ids")
	courierIDs, err := q.SelectCourierIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select courier ids: %w", err)
	}

	return courierIDs, nil
}

func createPayments(q *queries.Queries, cardIDs []int32) ([]int32, error) {
	log.Printf("Generating %d payments", OrderCount)
	payments := make([]queries.CreatePaymentsParams, 0, OrderCount)
	for range OrderCount {
		payments = append(payments, randomPayment(cardIDs))
	}

	log.Printf("Creating %d payments", len(payments))
	if _, err := q.CreatePayments(context.Background(), payments); err != nil {
		return nil, fmt.Errorf("create payments: %w", err)
	}

	log.Print("Selecting payment ids")
	paymentIDs, err := q.SelectPaymentIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select payment ids: %w", err)
	}

	return paymentIDs, nil
}

func createOrders(q *queries.Queries, userIDs, courierIDs, paymentIDs []int32) ([]int32, error) {
	log.Printf("Generating %d orders", OrderCount)
	orders := make([]queries.CreateOrdersParams, 0, OrderCount)
	for i := range OrderCount {
		orders = append(orders, randomOrder(paymentIDs[i], userIDs, courierIDs))
	}

	log.Printf("Creating %d orders", len(orders))
	if _, err := q.CreateOrders(context.Background(), orders); err != nil {
		return nil, fmt.Errorf("create orders: %w", err)
	}

	log.Print("Selecting order ids")
	orderIDs, err := q.SelectOrderIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select order ids: %w", err)
	}

	return orderIDs, nil
}

func createSuppliers(q *queries.Queries) ([]int32, error) {
	log.Printf("Generating %d suppliers", SupplierCount)
	suppliers := make([]queries.CreateSuppliersParams, 0, SupplierCount)
	for range SupplierCount {
		suppliers = append(suppliers, randomSupplier())
	}

	log.Printf("Creating %d suppliers", len(suppliers))
	if _, err := q.CreateSuppliers(context.Background(), suppliers); err != nil {
		return nil, fmt.Errorf("create suppliers: %w", err)
	}

	log.Print("Selecting supplier ids")
	supplierIDs, err := q.SelectSupplierIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select supplier ids: %w", err)
	}
	return supplierIDs, nil
}

func createDishes(q *queries.Queries, supplierIDs []int32) ([]int32, error) {
	log.Print("Generating dishes")
	dishes := make([]queries.CreateDishesParams, 0)
	for _, supplierID := range supplierIDs {
		h := hash(supplierID) % 3
		if h == 0 || h == 1 {
			dishCount := rand.IntN(MaxItemsPerSupplier-MinItemsPerSupplier) + MinItemsPerSupplier
			taken := make(map[int]struct{})
			for i := 0; i < dishCount; i++ {
				dishes = append(dishes, randomDish(supplierID, taken))
			}
		}
	}

	log.Printf("Creating %d dishes", len(dishes))
	if _, err := q.CreateDishes(context.Background(), dishes); err != nil {
		return nil, fmt.Errorf("create dishes: %w", err)
	}

	log.Print("Selecting dish ids")
	dishIDs, err := q.SelectDishIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select dish ids: %w", err)
	}

	return dishIDs, nil
}

func createCommodities(q *queries.Queries, supplierIDs []int32) ([]int32, error) {
	log.Print("Generating commodities")
	commodities := make([]queries.CreateCommoditiesParams, 0)
	for _, supplierID := range supplierIDs {
		h := hash(supplierID) % 3
		if h == 0 || h == 2 {
			commodityCount := rand.IntN(MaxItemsPerSupplier-MinItemsPerSupplier) + MinItemsPerSupplier
			taken := make(map[int]struct{})
			for i := 0; i < commodityCount; i++ {
				commodities = append(commodities, randomCommodity(supplierID, taken))
			}
		}
	}

	log.Printf("Creating %d commodities", len(commodities))
	if _, err := q.CreateCommodities(context.Background(), commodities); err != nil {
		return nil, fmt.Errorf("create commodities: %w", err)
	}

	log.Print("Selecting commodity ids")
	commodityIDs, err := q.SelectCommodityIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select commodity ids: %w", err)
	}

	return commodityIDs, nil
}

func createOrderCompositions(q *queries.Queries, orderIDs, dishIDs, commodityIDs []int32) error {
	log.Print("Generating order compositions")
	orderCompositions := make([]queries.AssignOrdersCommoditiesAndDishesParams, 0, len(orderIDs)*MaxItemsPerOrder)
	for _, orderID := range orderIDs {
		itemCount := rand.IntN(MaxItemsPerOrder-MinItemsPerOrder) + MinItemsPerOrder
		dishCount := rand.IntN(itemCount + 1)
		commodityCount := itemCount - dishCount

		for i := 0; i < dishCount; i++ {
			orderCompositions = append(orderCompositions, queries.AssignOrdersCommoditiesAndDishesParams{
				OrderID: orderID,
				DishID: pgtype.Int4{
					Int32: dishIDs[rand.IntN(len(dishIDs))],
					Valid: true,
				},
			})
		}

		for i := 0; i < commodityCount; i++ {
			orderCompositions = append(orderCompositions, queries.AssignOrdersCommoditiesAndDishesParams{
				OrderID: orderID,
				CommodityID: pgtype.Int4{
					Int32: commodityIDs[rand.IntN(len(commodityIDs))],
					Valid: true,
				},
			})
		}
	}

	log.Printf("Creating %d order compositions", len(orderCompositions))
	if _, err := q.AssignOrdersCommoditiesAndDishes(context.Background(), orderCompositions); err != nil {
		return fmt.Errorf("create order compositions: %w", err)
	}

	return nil
}

func createCategories(q *queries.Queries) ([]int32, error) {
	log.Printf("Creating %d categories", len(categories))
	if _, err := q.CreateCategories(context.Background(), categories); err != nil {
		return nil, fmt.Errorf("create categories: %w", err)
	}

	log.Print("Selecting category ids")
	categoryIDs, err := q.SelectCategoryIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select category ids: %w", err)
	}

	return categoryIDs, nil
}

func createCategoriesToTargets(q *queries.Queries, categoryIDs, dishIDs, commodityIDs []int32) error {
	log.Print("Generating categories to targets")
	categoriesToTargets := make([]queries.AssignCategoriesToTargetsParams, 0, len(categoryIDs)*len(dishIDs))

	for _, dishID := range dishIDs {
		if rand.IntN(5) == 0 {
			continue
		}

		categoriesToTargets = append(categoriesToTargets, queries.AssignCategoriesToTargetsParams{
			DishID: pgtype.Int4{
				Int32: dishID,
				Valid: true,
			},
			CategoryID: choose(categoryIDs),
		})
	}

	for _, commodityID := range commodityIDs {
		if rand.IntN(5) == 0 {
			continue
		}

		categoriesToTargets = append(categoriesToTargets, queries.AssignCategoriesToTargetsParams{
			CommodityID: pgtype.Int4{
				Int32: commodityID,
				Valid: true,
			},
			CategoryID: choose(categoryIDs),
		})
	}

	log.Printf("Creating %d categories to targets", len(categoriesToTargets))
	if _, err := q.AssignCategoriesToTargets(context.Background(), categoriesToTargets); err != nil {
		return fmt.Errorf("create categories to targets: %w", err)
	}

	return nil
}

func createDiscounts(q *queries.Queries) ([]int32, error) {
	log.Print("Creating discounts")
	discounts := make([]queries.CreateDiscountsParams, 0, DiscountCount)
	for i := 0; i < DiscountCount; i++ {
		discounts = append(discounts, randomDiscount())
	}

	log.Printf("Creating %d discounts", len(discounts))
	if _, err := q.CreateDiscounts(context.Background(), discounts); err != nil {
		return nil, fmt.Errorf("create discounts: %w", err)
	}

	log.Print("Selecting discount ids")
	discountIDs, err := q.SelectDiscountIDs(context.Background())
	if err != nil {
		return nil, fmt.Errorf("select discount ids: %w", err)
	}

	return discountIDs, nil
}

func createDiscountsToTargets(q *queries.Queries, discountIDs, dishIDs, commodityIDs []int32) error {
	log.Print("Generating discounts to targets")
	discountsToTargets := make([]queries.CreateDiscountTargetsParams, 0)

	for _, discountID := range discountIDs {
		var discountDishIDs, discountCommodityIDs []int32

		if rand.IntN(3) != 0 {
			discountDishIDs = make([]int32, rand.IntN(10)+1)
			alreadyChosen := make(map[int]struct{}, len(discountDishIDs))
			for i := range discountDishIDs {
				discountDishIDs[i] = chooseUniq(dishIDs, alreadyChosen)
			}
		}

		for _, dishID := range discountDishIDs {
			discountsToTargets = append(discountsToTargets, queries.CreateDiscountTargetsParams{
				DiscountID: discountID,
				DishID: pgtype.Int4{
					Int32: dishID,
					Valid: true,
				},
			})
		}

		if rand.IntN(3) != 0 || len(discountDishIDs) == 0 {
			discountCommodityIDs = make([]int32, rand.IntN(10)+1)
			alreadyChosen := make(map[int]struct{}, len(discountCommodityIDs))
			for i := range discountCommodityIDs {
				discountCommodityIDs[i] = chooseUniq(commodityIDs, alreadyChosen)
			}
		}

		for _, commodityID := range discountCommodityIDs {
			discountsToTargets = append(discountsToTargets, queries.CreateDiscountTargetsParams{
				DiscountID: discountID,
				CommodityID: pgtype.Int4{
					Int32: commodityID,
					Valid: true,
				},
			})
		}
	}

	log.Printf("Creating %d discounts to targets", len(discountsToTargets))
	if _, err := q.CreateDiscountTargets(context.Background(), discountsToTargets); err != nil {
		return fmt.Errorf("create discounts to targets: %w", err)
	}

	return nil
}
