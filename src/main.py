from api import ShahedFoodApi, rich_food_info
from json import dumps
from utils import write_file, write_file_bin


def select_food(foods) -> dict:
    return foods[0]


def select_selff(selves) -> dict:
    return selves[0]


def choose_food_to_reserve(week_program) -> list:
    result = []
    for day_program in week_program:
        for meal in day_program["Meals"]:
            # "LastReserved":
            if meal["MealState"] == 0:  # is available to choose
                food = select_food(meal["FoodMenu"])
                selff = select_selff(food["SelfMenu"])
                result.append(rich_food_info(
                    meal["Id"],
                    meal["MealId"],
                    meal["MealId"]-1,
                    meal["MealName"],
                    food["FoodId"],
                    food["FoodName"],
                    selff["Price"],
                    selff["SelfId"],
                    selff["SelfName"],
                    day_program["DayDate"],
                    day_program["DayId"],
                    day_program["DayTitle"]
                ))

    return result


if __name__ == "__main__":
    """
    usage 
    """
    sfa = ShahedFoodApi()

    (login_data, capcha_binary) = sfa.login_before_captcha()
    write_file_bin("./temp/capcha.png", capcha_binary)

    sfa.login_after_captcha(
        login_data,
        "992164019", "@123456789",
        input("read capcha: "))

    print(sfa.credit())
    weekProgram = sfa.reservation_program()
    write_file("./temp/data1.json", dumps(weekProgram, ensure_ascii=False))

    sss = choose_food_to_reserve(weekProgram)
    write_file("./temp/data2.json",
               dumps(sss, ensure_ascii=False))

    for s in sss:
        sfa.reserve_food(s)
        sfa.cancel_food(s)
