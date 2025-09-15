#!/usr/bin/env python3
"""
vil-copy-layer.py - 用于复制 Vial 键盘配置文件中的图层

用法:
  vil-copy-layer.py filename.vil source_layers target_layers

示例:
  vil-copy-layer.py keyboard.vil 0 1          # 复制 layer0 到 layer1
  vil-copy-layer.py keyboard.vil 1,3,2,4 4,3,2,1  # 复制多个图层
"""

import json
import sys
import os

def show_usage():
    """显示使用说明"""
    print(__doc__)
    sys.exit(1)

def parse_layer_list(layer_str):
    """解析图层列表字符串"""
    try:
        return [int(x.strip()) for x in layer_str.split(',')]
    except ValueError:
        print(f"错误: 无效的图层格式 '{layer_str}'")
        show_usage()

def copy_layers(filename, source_layers, target_layers):
    """执行图层复制操作"""
    # 检查源和目标图层数量是否匹配
    if len(source_layers) != len(target_layers):
        print(f"错误: 源图层数量({len(source_layers)})和目标图层数量({len(target_layers)})不匹配")
        sys.exit(1)
    
    # 检查是否有重复的目标图层
    if len(target_layers) != len(set(target_layers)):
        print("错误: 目标图层列表包含重复值")
        sys.exit(1)
    
    # 读取文件
    try:
        with open(filename, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"错误: 文件 '{filename}' 不存在")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"错误: 文件 '{filename}' 不是有效的 JSON 格式")
        sys.exit(1)
    
    # 检查文件是否包含布局数据
    if 'layout' not in data:
        print("错误: 文件不包含布局数据")
        sys.exit(1)
    
    layout = data['layout']
    max_layer = len(layout) - 1
    
    # 检查所有图层索引是否有效
    for layer in source_layers + target_layers:
        if layer < 0 or layer > max_layer:
            print(f"错误: 图层 {layer} 超出范围 (0-{max_layer})")
            sys.exit(1)
    
    # 创建备份
    backup_filename = filename + '.bak'
    try:
        with open(backup_filename, 'w') as f:
            json.dump(data, f, indent=4)
        print(f"已创建备份: {backup_filename}")
    except:
        print("警告: 无法创建备份文件")
    
    # 先保存所有源图层的副本
    source_data = {}
    for layer in source_layers:
        source_data[layer] = layout[layer].copy()
    
    # 然后将保存的数据复制到目标图层
    for i in range(len(source_layers)):
        src_layer = source_layers[i]
        tgt_layer = target_layers[i]
        layout[tgt_layer] = source_data[src_layer].copy()
        print(f"已复制图层 {src_layer} 到图层 {tgt_layer}")
    
    # 写回文件
    try:
        with open(filename, 'w') as f:
            json.dump(data, f, indent=4)
        print(f"成功更新文件: {filename}")
    except:
        print("错误: 无法写入文件")
        sys.exit(1)

def main():
    # 检查参数数量
    if len(sys.argv) != 4:
        show_usage()
    
    filename = sys.argv[1]
    source_layers_str = sys.argv[2]
    target_layers_str = sys.argv[3]
    
    # 解析图层列表
    source_layers = parse_layer_list(source_layers_str)
    target_layers = parse_layer_list(target_layers_str)
    
    # 执行复制操作
    copy_layers(filename, source_layers, target_layers)

if __name__ == "__main__":
    main()
