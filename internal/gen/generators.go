package gen

import (
	"crypto/sha256"
	_ "embed"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"hash/crc64"
	"math/big"
	"math/rand/v2"
	"strings"
	"time"

	"github.com/brianvoe/gofakeit/v7"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/LeKSuS-04/mephi-db/internal/db/queries"
)

//go:embed data.json
var data string

type CommonDishCommodityData struct {
	Name        string   `json:"name"`
	Ingredients []string `json:"ingredients"`
	Weight      int      `json:"weight"`
	Nutrition   struct {
		Calories int `json:"calories"`
		Protein  int `json:"protein"`
		Fat      int `json:"fat"`
		Carbs    int `json:"carbs"`
	} `json:"nutrition"`
	Allergens []string `json:"allergens"`
	Rating    float64  `json:"rating"`
}

type DishData struct {
	CommonDishCommodityData `json:",inline"`
	Cuisine                 string `json:"cuisine"`
}

type CommodityData struct {
	CommonDishCommodityData `json:",inline"`
	Category                string `json:"category"`
}

type PredefinedData struct {
	Dishes      []DishData      `json:"dishes"`
	Commodities []CommodityData `json:"commodities"`
}

var predefinedData PredefinedData
var categories []string
var usedEmails = make(map[string]struct{}, UserCount)

func init() {
	var err error
	if err = json.Unmarshal([]byte(data), &predefinedData); err != nil {
		panic(err)
	}

	uniqCategories := make(map[string]struct{}, len(predefinedData.Dishes)+len(predefinedData.Commodities))
	for _, dish := range predefinedData.Dishes {
		uniqCategories[dish.Cuisine] = struct{}{}
	}
	for _, commodity := range predefinedData.Commodities {
		uniqCategories[commodity.Category] = struct{}{}
	}

	categories = make([]string, 0, len(uniqCategories))
	for cat := range uniqCategories {
		categories = append(categories, cat)
	}
}

func randomUser() queries.CreateUsersParams {
	password := gofakeit.Password(true, true, true, true, true, 32)
	h := sha256.Sum256([]byte(password))
	hash := hex.EncodeToString(h[:])

	email := gofakeit.Email()
	_, ok := usedEmails[email]
	for ok {
		email = gofakeit.Email()
		_, ok = usedEmails[email]
	}
	usedEmails[email] = struct{}{}

	return queries.CreateUsersParams{
		Name: pgtype.Text{
			String: gofakeit.FirstName(),
			Valid:  true,
		},
		Surname: pgtype.Text{
			String: gofakeit.LastName(),
			Valid:  true,
		},
		Email: pgtype.Text{
			String: email,
			Valid:  true,
		},
		Phone: pgtype.Text{
			String: gofakeit.Phone(),
			Valid:  true,
		},
		PasswordHash: pgtype.Text{
			String: hash,
			Valid:  true,
		},
	}
}

func randomCard(userID int32) queries.CreateUserCardsParams {
	gofakeit.MinecraftFood()
	return queries.CreateUserCardsParams{
		UserID: userID,
		Number: gofakeit.CreditCardNumber(&gofakeit.CreditCardOptions{
			Types: []string{"visa", "mastercard"},
			Bins:  []string{"4", "5"},
			Gaps:  false,
		}),
	}
}

func randomAddress(userID int32) queries.CreateUserAddressesParams {
	return queries.CreateUserAddressesParams{
		UserID:  userID,
		Address: gofakeit.Address().Address,
	}
}

func randomCourier() queries.CreateCourieresParams {
	return queries.CreateCourieresParams{
		Name:   gofakeit.Name(),
		Phone:  gofakeit.Phone(),
		Rating: randomRating(),
	}
}

func randomPayment(cardIDs []int32) queries.CreatePaymentsParams {
	method := choose([]string{"cash", "card", "online", "online", "online", "online", "online"})
	status := "successful"
	if method == "online" && rand.IntN(20) == 0 {
		status = "failed"
	}

	var cardID int32 = -1
	if method == "online" {
		cardID = choose(cardIDs)
	}

	return queries.CreatePaymentsParams{
		Method: method,
		Status: status,
		CardID: pgtype.Int4{Int32: cardID, Valid: cardID != -1},
		Timestamp: pgtype.Timestamp{
			Time:  gofakeit.DateRange(time.Now().Add(-365*24*time.Hour), time.Now()),
			Valid: true,
		},
	}
}

func randomOrder(paymentID int32, userIDs, courierIDs []int32) queries.CreateOrdersParams {
	var status string
	rng := rand.IntN(100)
	switch {
	case rng == 0:
		status = "canceled"
	case rng < 3:
		status = "in_progress"
	default:
		status = "delivered"
	}

	return queries.CreateOrdersParams{
		UserID: pgtype.Int4{
			Int32: choose(userIDs),
			Valid: true,
		},
		SourceAddress: pgtype.Text{
			String: gofakeit.Address().Address,
			Valid:  true,
		},
		TargetAddress: pgtype.Text{
			String: gofakeit.Address().Address,
			Valid:  true,
		},
		CourierID: pgtype.Int4{
			Int32: choose(courierIDs),
			Valid: true,
		},
		Status: pgtype.Text{
			String: status,
			Valid:  true,
		},
		Timestamp: pgtype.Timestamp{
			Time:  gofakeit.DateRange(time.Now().Add(-365*24*time.Hour), time.Now()),
			Valid: true,
		},
		PaymentID: pgtype.Int4{
			Int32: paymentID,
			Valid: true,
		},
	}
}

func randomSupplier() queries.CreateSuppliersParams {
	return queries.CreateSuppliersParams{
		Name: gofakeit.Company(),
		WorkTimeStart: pgtype.Time{
			Microseconds: rand.Int64N(16) * 30 * 60 * 1_000_000,
			Valid:        true,
		},
		WorkTimeEnd: pgtype.Time{
			Microseconds: 12*3600*1_000_000 + rand.Int64N(16)*1800*1_000_000,
			Valid:        true,
		},
		Rating:  randomRating(),
		Address: gofakeit.Address().Address,
	}
}

func randomDish(supplierID int32, alreadyChosen map[int]struct{}) queries.CreateDishesParams {
	dish := chooseUniq(predefinedData.Dishes, alreadyChosen)
	return queries.CreateDishesParams{
		Name: dish.Name,
		Ingredients: pgtype.Text{
			String: strings.Join(dish.Ingredients, ", "),
			Valid:  true,
		},
		Weight:     int32(dish.Weight),
		Calories:   int32(dish.Nutrition.Calories),
		Allergens:  strings.Join(dish.Allergens, ", "),
		Rating:     randomRating(),
		SupplierID: supplierID,
		Cost:       10*rand.Int64N(990) + 100,
		Image:      nil,
	}
}

func randomCommodity(supplierID int32, alreadyChosen map[int]struct{}) queries.CreateCommoditiesParams {
	commodity := chooseUniq(predefinedData.Commodities, alreadyChosen)
	return queries.CreateCommoditiesParams{
		Name:        commodity.Name,
		Ingredients: strings.Join(commodity.Ingredients, ", "),
		Weight:      int32(commodity.Weight),
		Rating:      randomRating(),
		SupplierID:  supplierID,
		Cost:        10*rand.Int64N(990) + 100,
		Image:       nil,
	}
}

func randomDiscount() queries.CreateDiscountsParams {
	type PercentageDiscount struct {
		Percentage int `json:"percentage"`
	}

	type ConstDiscount struct {
		Value int `json:"value"`
	}

	type ExtraForFree struct {
		MustBy     int `json:"must_by"`
		GetForFree int `json:"get_for_free"`
	}

	var typ string
	var jsonBytes []byte
	var discount any
	switch rand.IntN(3) {
	case 0:
		typ = "percentage"
		discount = PercentageDiscount{
			Percentage: rand.IntN(30),
		}

	case 1:
		typ = "const"
		discount = ConstDiscount{
			Value: rand.IntN(10) * 100,
		}

	case 2:
		typ = "extra_for_free"
		discount = ExtraForFree{
			MustBy:     rand.IntN(5) + 1,
			GetForFree: rand.IntN(2) + 1,
		}
	}

	jsonBytes, _ = json.Marshal(discount)

	return queries.CreateDiscountsParams{
		Name:        gofakeit.AppName(),
		Description: gofakeit.LoremIpsumParagraph(rand.IntN(3)+1, rand.IntN(5)+2, rand.IntN(5)+10, "\n\n"),
		Type:        typ,
		Terms:       jsonBytes,
		Active:      rand.IntN(2) == 0,
	}
}

func randomRating() pgtype.Numeric {
	return pgtype.Numeric{
		Int:   big.NewInt(rand.Int64N(400) + 100),
		Exp:   -2,
		Valid: true,
	}
}

func choose[T any](values []T) T {
	return values[rand.IntN(len(values))]
}

func chooseUniq[T any](values []T, alreadyChosen map[int]struct{}) T {
	idx := rand.IntN(len(values))
	_, ok := alreadyChosen[idx]
	for ok {
		idx = (idx + 1) % len(values)
		_, ok = alreadyChosen[idx]
	}
	alreadyChosen[idx] = struct{}{}
	return values[idx]
}

var crcTable = crc64.MakeTable(crc64.ISO)

func hash(value int32) int {
	bytes := make([]byte, 4)
	binary.LittleEndian.PutUint32(bytes, uint32(value))
	crc64 := crc64.Checksum(bytes, crcTable)
	return int(crc64)
}
