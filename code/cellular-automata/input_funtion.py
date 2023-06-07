import xlrd
from decimal import Decimal
import pandas as pd
import re

name = 'model1'  # 读取文件的文件名


def datawash():  # 数据清洗

    file = name + '.csv'
    # 导入数据,第一行不作为列名
    wb = pd.read_csv(file, header=None)
    df = pd.DataFrame(wb)  # 创建dataframe
    df.columns = ["x", "z", "y"]  # 指定列序为xzy
    df.sort_values(by=['x', 'y'], ascending=True, inplace=True)  # 基于x和y进行排序，ascending为true，降序,inplace=True覆盖df数据
    df.to_excel(name + ".xlsx", header=False, index=False)  # 输出已排序的excel，无列名方便后面读取


# 输入函数
def inputpoint():
    datawash()
    # 获取所有点sum_point
    sum_point = []
    # 每个点对应的z值
    dic_z = {}

    # 定义x和y的总数
    sum_x, sum_y, interval = 0, 0, 0
    # 从Excel中导入数据
    wb = xlrd.open_workbook(name + ".xlsx")
    sheet = wb.sheet_by_index(0)
    rows = sheet.nrows

    # 标记出x，y值
    flag_x = sheet.cell(0, 0).value
    flag_y = sheet.cell(0, 2).value

    for i in range(rows):
        one_data_x = round(sheet.cell(i, 0).value)
        one_data_y = round(sheet.cell(i, 2).value)
        one_data_z = sheet.cell(i, 1).value
        if flag_x == one_data_x:
            sum_y += 1
        if flag_y == one_data_y:
            sum_x += 1
        # sum_point记录所有x，y点的坐标
        sum_point.append([one_data_x, one_data_y])
        dic_z[(one_data_x, one_data_y)] = one_data_z

    interval = round(sum_point[0][0] - sum_point[sum_y][0], len(str(sum_point[0][0])))

    # print(dic_z)

    # dir_point代表了方向导数，dic_point_path代表前往各个方向的路程，estimate_Nabla代表每个点所具备的梯度值
    dir_point, dic_point_path, estimate_Nabla = modified_Nabla(sum_point, interval, sum_x, sum_y, dic_z)
    # print(dir_point)
    # print(dic_point_path)
    # print(estimate_Nabla)

    pandas_csv(sum_point, dir_point, dic_point_path, estimate_Nabla, sum_x, sum_y)

    print('Done!')


def pandas_csv(sum_point, dir_point, dic_point_path, estimate_Nabla, sum_x, sum_y):
    data = []
    for i in range(sum_x):
        for j in range(sum_y):
            data1 = []
            pattern = re.compile(r',')

            a = str(dic_point_path[tuple(sum_point[i * sum_x + j])])
            a = pattern.sub('', a)
            b = str(dir_point[tuple(sum_point[i * sum_x + j])])
            b = pattern.sub('', b)
            data1.append(b)
            data1.append(a)
            data1.append(str(estimate_Nabla[i * sum_x + j]))
            data.append(data1)
    print(data)
    df = pd.DataFrame(data, columns=['K', 'S', '梯度'], dtype=float)
    # print(type(b))
    # print(data)
    df.to_csv('2.csv', index=False,header=False)


def modified_Nabla(sum_point, interval, sum_x, sum_y, dic_z):
    # 定义方向向量（以如下方式定义方向向量，第一个值代表x的变化量，第二个值代表y的变化量，第三个值表示权重）
    # y轴
    # |  ...
    # |  ...
    # |  ...
    # -------x轴

    # direction = [[-interval, -interval, 2 ** 0.5], [-interval, 0, 1], [-interval, interval, 2 ** 0.5],
    #              [0, -interval, 1], [0, interval, 1],
    #              [interval, -interval, 2 ** 0.5], [interval, 0, 1], [interval, interval, 2 ** 0.5]]
    # 顺序输出对应数组
    direction = [[interval, 0, 1], [interval, interval, 2 ** 0.5],[0, interval, 1],[-interval, interval, 2 ** 0.5],[-interval, 0, 1],[-interval, -interval, 2 ** 0.5],[0, -interval, 1],[interval, -interval, 2 ** 0.5]]
    # 记录各个点的方向导数值
    dir_point, dic_point_path = {}, {}
    estimate_Nabla = []
    # 添加边界无效点以方便标准化读取
    for i in range(sum_y):
        dir_point.update({tuple(sum_point[i]): [0, 0, 0, 0, 0, 0, 0, 0]})
        dic_point_path.update({tuple(sum_point[i]): [0, 0, 0, 0, 0, 0, 0, 0]})
        estimate_Nabla.append(0)
    # 去除边界点，计算8个方向的方向导数与估计出的梯度值
    for i in range(1, sum_x - 1):
        dir_point.update({tuple(sum_point[i * sum_x]): [0, 0, 0, 0, 0, 0, 0, 0]})
        dic_point_path.update({tuple(sum_point[i * sum_x]): [0, 0, 0, 0, 0, 0, 0, 0]})
        estimate_Nabla.append(0)
        for j in range(1, sum_y - 1):
            dire_new_point, dire_new_point_path, estimate_new_Nabla = Directional_derivatives(sum_point[i * sum_x + j],
                                                                                              direction, dic_z,
                                                                                              interval)
            dir_point.update(dire_new_point)
            dic_point_path.update(dire_new_point_path)
            estimate_Nabla.append(estimate_new_Nabla)
        dir_point.update({tuple(sum_point[i * sum_x + sum_y - 1]): [0, 0, 0, 0, 0, 0, 0, 0]})
        dic_point_path.update({tuple(sum_point[i * sum_x + sum_y - 1]): [0, 0, 0, 0, 0, 0, 0, 0]})
        estimate_Nabla.append(0)
    # 补齐下边无效点
    for i in range(sum_y):
        dir_point.update({tuple(sum_point[sum_x ** 2 - sum_x + i]): [0, 0, 0, 0, 0, 0, 0, 0]})
        dic_point_path.update({tuple(sum_point[sum_x ** 2 - sum_x + i]): [0, 0, 0, 0, 0, 0, 0, 0]})
        estimate_Nabla.append(0)
    return dir_point, dic_point_path, estimate_Nabla


def Directional_derivatives(pointxy, direction, dic_z, interval):
    dire_point, dire_point_path, dic_point, dic_point_path = [], [], {}, {}
    for direction_text in direction:
        x = float(Decimal(str(pointxy[0])) + Decimal(str(direction_text[0])))
        y = float(Decimal(str(pointxy[1])) + Decimal(str(direction_text[1])))

        if abs(direction_text[0]) == interval and abs(direction_text[1]) == interval and dic_z[(x, y)] == 0:
            direction_path_hard = 2 ** 0.5
        else:
            direction_path_hard = ((interval * direction_text[2]) ** 2 + dic_z[(x, y)] ** 2) ** 0.5

        dire_point_xy = dic_z[(x, y)] / direction_text[2]

        dire_point.append(dire_point_xy)
        dire_point_path.append(direction_path_hard)
    estimate_Nabla = getMaxValue(dire_point)
    dic_point[(pointxy[0], pointxy[1])] = dire_point
    dic_point_path[(pointxy[0], pointxy[1])] = dire_point_path

    return dic_point, dic_point_path, estimate_Nabla


def getMaxValue(mylist):
    # 结束条件
    if len(mylist) == 0:
        return 0
    else:
        max_point = mylist[0]
        for i in range(1, len(mylist)):
            if abs(max_point) < abs(mylist[i]):
                max_point = mylist[i]
        return max_point


if __name__ == '__main__':
    inputpoint()
