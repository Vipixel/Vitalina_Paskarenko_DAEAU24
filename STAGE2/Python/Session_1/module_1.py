from typing import List


def task_1(array: List[int], target: int) -> List[int]:
    seen_numbers = set()
    for num in array:
        point = target - num
        if point in seen_numbers:
            return [point,num]
        seen_numbers.add(num)
    return []
    


def task_2(number: int) -> int:
    reversed_number = 0
    is_negative = number < 0
    number = abs(number)  
    while number > 0:
        reversed_number = reversed_number * 10 + number % 10
        number = number // 10
    if is_negative:
        reversed_number = -reversed_number
    
    return reversed_number


def task_3(array: List[int]) -> int:
    seen_numbers = set()
    for num in array:
        if num in seen_numbers:
            return num
        seen_numbers.add(num)
    return -1

def task_4(string: str) -> int:
    """
    Write your code below
    """
    roman_to_value = {
        'I': 1, 'V': 5, 'X': 10,
        'L': 50, 'C': 100,
        'D': 500, 'M': 1000
    }
    total = 0
    n = len(string)

    for i in range(n):
        current_value = roman_to_value[string[i]]
        if i < n - 1 and current_value < roman_to_value[string[i + 1]]:
            total -= current_value
        else:
            total += current_value

    return total


def task_5(array: List[int]) -> int:
    result = array[0]

    for num in array:
        if num < result:
            result = num
    return result
