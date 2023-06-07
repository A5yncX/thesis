import re

fp = open('demo.csv', mode='r+')

# rule1：正则，取消连续2个以上的,
pattern = re.compile(r',{2,}')

content = fp.read()
# rule1的实现
rule1 = pattern.sub('', content)
# 基于换行符\n存储每行为数组
data1 = rule1.split('\n')
res, res_done = [], []
# rule2：对""进行转义，添加到每行左右两侧，如果为空则不添加""
for data2 in data1:
    if data2 != '':
        rule2 = "\"" + data2 + "\""
    else:
        rule2 = data2
    res.append(rule2)  # rule2的实现
for rule2 in res:
    res_i = list(rule2)
    res_j = res_i.copy()
    flag = 0
    # rule3：逗号左右有数据但没有""，分别判断添加。
    for i in range(len(res_i)):
        if res_i[i] == ',':
            if res_i[i - 1] == "\"" and res_i[i + 1] != "\"":
                res_j.insert(i + flag + 1, "\"")
                flag += 1
            elif res_i[i - 1] != "\"" and res_i[i + 1] == "\"":
                res_j.insert(i + flag, "\"")
                flag += 1
            elif res_i[i - 1] != "\"" and res_i[i + 1] != "\"":
                res_j.insert(i + flag + 1, "\"")
                res_j.insert(i + flag, "\"")
                flag += 2
    rule3 = ''.join(res_j)
    res_done.append(rule3)

res_final = "\n".join(res_done)

fp.seek(0)
fp.write(res_final)
fp.close()
print('done!')
