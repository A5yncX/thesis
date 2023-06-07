import xlrd
from decimal import Decimal
import pandas as pd

name = '1'  # 读取文件的文件名


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
        one_data_x = sheet.cell(i, 0).value
        one_data_y = sheet.cell(i, 2).value
        one_data_z = sheet.cell(i, 1).value
        if flag_x == one_data_x:
            sum_y += 1
        if flag_y == one_data_y:
            sum_x += 1
        sum_point.append([one_data_x, one_data_y])
        dic_z[(one_data_x, one_data_y)] = one_data_z

    interval = round(sum_point[0][0] - sum_point[sum_y][0], len(str(sum_point[0][0])))

    print(dic_z)

    print(modified_Nabla(sum_point, interval, sum_x, sum_y, dic_z))


def modified_Nabla(sum_point, interval, sum_x, sum_y, dic_z):
    # 定义方向向量（以如下方式定义方向向量，第一个值代表x的变化量，第二个值代表y的变化量，第三个值表示权重）
    # -------y轴
    # |  ...
    # |  ...
    # |  ...
    # x轴
    direction = [[-interval, -interval, 2 ** 0.5], [-interval, 0, 1], [-interval, interval, 2 ** 0.5],
                 [0, -interval, 1], [0, 0, 1], [0, interval, 1],
                 [interval, -interval, 2 ** 0.5], [interval, 0, 1], [interval, interval, 2 ** 0.5]]
    # 记录各个点的方向导数值
    dire_point = {}
    # 去除边界点，计算8个方向的方向导数与估计出的梯度值
    for i in range(1, sum_x - 1):
        for j in range(1, sum_y - 1):
            dire_new_point, estimate_Nabla = Directional_derivatives(sum_point[i * sum_x + j], direction, dic_z)
            dire_point.update(dire_new_point)

    return dire_point, estimate_Nabla


def Directional_derivatives(pointxy, direction, dic_z):
    dire_point, dic_point = [], {}
    for direction_text in direction:
        x = float(Decimal(str(pointxy[0])) + Decimal(str(direction_text[0])))
        y = float(Decimal(str(pointxy[1])) + Decimal(str(direction_text[1])))

        dire_point_xy = dic_z[(x, y)] / direction_text[2]
        dire_point.append(dire_point_xy)
    estimate_Nabla = max(dire_point)
    dic_point[(pointxy[0], pointxy[1])] = dire_point

    return dic_point, estimate_Nabla


if __name__ == '__main__':
    inputpoint()
