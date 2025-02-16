from collections import defaultdict
from collections import Counter
from itertools import product

from typing import Any, Dict, List, Tuple


def task_1(data_1: Dict[str, int], data_2: Dict[str, int]):
    counter1 = Counter(data_1)
    counter2 = Counter(data_2)

    total = counter1 + counter2 
    
    return dict(total)


def task_2():
    new_dict = dict()
    expected = {idx: idx**2 for idx in range(1, 16)}

    for key, value in expected.items():
        if key >=1 and key <=15:
            new_dict[key] = value**2
        return new_dict

def task_3(data: Dict[Any, List[str]]):
    combinations = ['']

    for key in data:
        new_combinations = []
        for combo in combinations:
            for letter in data[key]:
                new_combinations.append(combo + letter)
        combinations = new_combinations

    return combinations

def task_4(data: Dict[str, int]):
    sorted_items = sorted(data.items(), key=lambda item: item[1], reverse=True)
    
    top_keys = []
    for key, value in sorted_items[:3]:
        top_keys.append(key)

    return top_keys


def task_5(data: List[Tuple[Any, Any]]) -> Dict[str, List[int]]:
    
    group_d = defaultdict(list)
    
    for key, value in data:
        group_d[key].append(value)

    return dict(group_d)


def task_6(data: List[Any]):
    seen = set()
    result = []
    
    for item in data:
        if item not in seen:
            result.append(item) 
            seen.add(item) 

    return result

def task_7(words: List[str]) -> str:
    if not words:
        return "" 
    prefix = words[0]
    for string in words[1:]:
        while not string.startswith(prefix):
            prefix = prefix[:-1]
            if not prefix:
                return ""
    return prefix 

def task_8(haystack: str, needle: str) -> int:
    if needle == "":
        return 0  
    return haystack.find(needle)
