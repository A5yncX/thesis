import random
import numpy as np
import math

import pandas as pd


class humen():

    # 以下比例来源于国家统计局2020年数据,只考虑10岁以上人群
    def __init__(self, judge_gender, judge_age, judge_character, dx):
        self.judge_gender = judge_gender
        self.judge_age = judge_age
        self.judge_character = judge_character
        self.f = []
        # 按人口比例随机性别
        if (self.judge_gender <= 0.4876):
            self.gender = '0'  # 女
        else:
            self.gender = '1'  # 男

        # 按人口比例随机年龄，且将其划分为4个年龄层，【青少年（10-19），青壮年（20-34），成年期（35-59）,老年期（60-74）】
        if (self.judge_age <= 0.134416):
            self.age = random.randrange(10, 20)
        elif (0.134416 < self.judge_age <= 0.134416 + 0.247688):
            self.age = random.randrange(20, 35)
        elif (0.134416 + 0.247688 < self.judge_age <= 0.134416 + 0.247688 + 0.4502):
            self.age = random.randrange(35, 60)
        else:
            self.age = random.randrange(60, 75)

        # 按照不同年龄段给出的标准身高数值与估计出的方差以高斯分布的形式随机对个体取值
        if (self.gender == '1'):
            # 性别恐慌因子
            fg = abs(round(random.gauss(0, 0.5), 2))
            # 14岁以下的男孩生长速度较快，将随机值抽离出来
            if (self.age <= 14):
                # 身高：单位cm
                self.height = round(random.gauss(140.2 + (self.age - 10) * 6.41, 2.1 - (self.age - 10) * 0.02), 2)
                # 体重：单位kg
                self.weight = round(random.gauss(33.74 + (self.age - 10) * 5.57, 2.24 + (self.age - 10) * 0.04), 2)
                # 随年龄变化的恐慌因子
                fa = abs(round(random.gauss(1.1, 0.2), 2))
            elif (14 < self.age <= 19):
                self.height = round(random.gauss(169.8 + (self.age - 15) * 0.51, 2.1 - (self.age - 10) * 0.02), 2)
                self.weight = round(random.gauss(57.08 + (self.age - 15) * 1.42, 2.28 - (self.age - 10) * 0.03), 2)
                fa = abs(round(random.gauss(0.9, 0.2), 2))
            elif (19 < self.age <= 44):
                self.height = round(random.gauss(174.2, 2.93), 2)
                self.weight = round(random.gauss(69.6, 2.12), 2)
                fa = abs(round(random.gauss(0.55, 0.2), 2))
            elif (44 < self.age):
                self.height = round(random.gauss(167.1, 2.41), 2)
                self.weight = round(random.gauss(62.3, 2.53), 2)
                fa = abs(round(random.gauss(0.25, 0.2), 2))
        else:
            fg = abs(round(random.gauss(1.4, 0.5), 2))
            # 14岁以下的女孩大概每年标准身高会增加3.96cm
            if (self.age <= 14):
                self.height = round(random.gauss(140.1 + (self.age - 10) * 3.96, 2.1 - (self.age - 10) * 0.05), 2)
                self.weight = round(random.gauss(31.76 + (self.age - 10) * 2.014, 2.21 + (self.age - 10) * 0.04), 2)
                fa = abs(round(random.gauss(1.1, 0.2), 2))
            elif (14 < self.age <= 19):
                self.height = round(random.gauss(160.8 + (self.age - 15) * 0.2, 1.9 - (self.age - 15) * 0.05), 2)
                self.weight = round(random.gauss(49.82 + (self.age - 15) * 0.61, 2.13 - (self.age - 15) * 0.03), 2)
                fa = abs(round(random.gauss(0.9, 0.2), 2))
            elif (19 < self.age <= 44):
                self.height = round(random.gauss(158.0, 1.93), 2)
                self.weight = round(random.gauss(59.3, 2.12), 2)
                fa = abs(round(random.gauss(0.55, 0.2), 2))
            elif (44 < self.age):
                self.height = round(random.gauss(155.8, 2.13), 2)
                self.weight = round(random.gauss(56.4, 2.12), 2)
                fa = abs(round(random.gauss(0.25, 0.2), 2))

        # 个人个性 取自OCEAN性格分析模型 且将人群性格取值为正态分布
        # 开明性(Openness) 、责任(Conscientiousness) 、外向(Extraversion) 、宜人性(Agreeableness)和神经质性(Neuroticism), 该模型又被称为FFM大五分类模型
        if (-0.8 < judge_character <= 0.8):
            self.character = 3
            fp = abs(round(random.gauss(0.55, 0.2), 2))
        elif (-1.6 < judge_character <= -0.8):
            self.character = 2
            fp = abs(round(random.gauss(0.72, 0.2), 2))
        elif (0.8 <= judge_character < 1.6):
            self.character = 4
            fp = abs(round(random.gauss(0.38, 0.2), 2))
        elif (judge_character <= -1.6):
            self.character = 1
            fp = abs(round(random.gauss(0.25, 0.2), 2))
        else:
            self.character = 5
            fp = abs(round(random.gauss(0.90, 0.2), 2))

        self.f.extend([fp, fg, fa])

        self.speed = self.humen_forceSelf()

        self.actual_climb, self.actual_climb_derivative = self.human_climbable(dx)

    def humen_forceSelf(self):
        # 认为在各个年龄段中锻炼时间大致呈高斯分布，且以锻炼的频率来决定个体的运动能力wp
        wp = abs(round(random.gauss(0.5, 0.157), 2))
        # 性别对应步幅能力
        if (self.gender == '1'):
            wg = np.pi * 4 / 9
            w3 = 0.41
        else:
            wg = np.pi / 3
            w3 = 0.2
        # 运动能力随年龄大致呈β分布
        wa = beta((self.age - 10) / 65, 2, 5) / 2.46

        w1 = 0.5
        w2 = 1.2
        path_frequency = (wp + 1) * w1 + (wa + 1) * w2 + w3

        path_longth = (self.height * 0.618) * math.cos(np.pi / 2 - wg / 2) * 2 / 100
        print(path_longth)

        self.sport_able = [wp, wa]

        return path_frequency * path_longth

    def human_climbable(self,dx):
        # 个体的基础攀爬值
        climb_base = self.height * (self.sport_able[1] / 0.5) ** (1/8) * 0.2
        # 针对个体的年龄和运动量来评判可攀爬的高度
        age_climb_reference = 1 - self.sport_able[1]

        # 3为修正参数，数值越大，因变量的值越集中
        sport_climb_reference = abs(1 - self.sport_able[0]) ** 3
        n = abs(random.gauss(0, sport_climb_reference))
        if (n >= 1 - age_climb_reference):
            able = 0
        else:
            # 0.8为正常人可攀爬的比例高度
            able = 0.8 - (n + age_climb_reference) * 0.8
        # 特殊值判断,10岁的儿童和75岁的老人
        if (self.sport_able[1] == 0):
            self.climb_base = 0.1
            self.climb_base_derivative = self.climb_base / dx
            actual_climb = random.uniform(0.1,0.2) * self.height / 100
            return actual_climb, actual_climb / dx
        # 在此认为女性普遍攀爬高度的权重为0.7
        if (self.gender == '0'):
            actual_climb = (able * self.height + climb_base) * 0.7 / 100 + 0.1 * self.height / 100
        else:
            actual_climb = (able * self.height + climb_base + 0.1 * self.height) / 100

        self.climb_base = climb_base / 100
        self.climb_base_derivative = self.climb_base / dx
        return actual_climb, actual_climb / dx

def gamma_function(n):
    cal = 1
    for i in range(2, n):
        cal *= i
    return cal


def beta(x, a, b):
    gamma = gamma_function(a + b) / \
            (gamma_function(a) * gamma_function(b))
    y = gamma * (x ** (a - 1)) * ((1 - x) ** (b - 1))
    return y


if __name__ == '__main__':
    data = []
    total_humen = int(input("请输入总人数："))
    dx = float(input("请输入每个之间的固定间隔dx："))
    for i in range(total_humen):
        judge_gender = random.random()
        judge_age = random.random()
        judge_character = random.gauss(0, 1)
        data1 = []
        a = humen(judge_gender, judge_age, judge_character, dx)
        data1 = [a.gender, round(a.height/100, 2), a.weight, a.age, a.character, str(a.f), round(a.speed, 2),
                 a.actual_climb, a.actual_climb_derivative,
                 a.climb_base, a.climb_base_derivative]
        data.append(data1)
        # print(a.gender, a.height, a.weight, a.age, a.character, a.f, a.speed)
    df = pd.DataFrame(data, dtype=float)
    df.to_csv("3.csv", index=False,header=False)
