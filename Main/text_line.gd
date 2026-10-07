extends PanelContainer

# 行高不再写死：根节点本身就是 PanelContainer，高度由 Label 的换行内容自动撑开，
# 行与行之间的间距统一交给 Main/main.tscn 里 TextList 的 separation 控制。
