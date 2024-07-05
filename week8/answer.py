"""
現時点では、SnowflakeとStreamlitの統合はまだ実現していませんが、FrostyFridayはそれを理由に、早めにStreamlitのスキルを身につけることを推奨しています。

StreamlitはPythonベースですが、このチャレンジはPython任意となっており、Pythonの知識がなくても取り組めるようになっています。以下のスケルトンスクリプトを使えば、Pythonの知識がなくてもこのチャレンジを実行できます。

スタートガイドについてはこちらを参照してください。

では、チャレンジ内容とは何でしょうか？

ある企業が簡単な支払い事実テーブルを持っています。そのデータはここにあります。FrostyDataにデータを取り込んで、以下の折れ線グラフを作成することを依頼しています。

結果:

スクリプトはパスワードを公開してはなりません。非常に危険なので、代わりにStreamlitのシークレットを使用してください。
タイトルは「2021年の支払い」とします。
「最小日付」フィルターを設け、ユーザーが選択できる最も早い日付を指定します。デフォルトでは選択可能な最も早い日付に設定してください。
「最大日付」フィルターを設け、ユーザーが選択できる最も遅い日付を指定します。デフォルトでは選択可能な最も遅い日付に設定してください。
X軸に日付、Y軸に金額を示す折れ線グラフを作成します。データは週ごとに集計されるべきです。
"""
import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

# CSVファイルの読み込み
file_path = 'payments.csv'  # 実際のファイルパスに変更してください
payments_df = pd.read_csv(file_path)

# 日付列をdatetime型に変換
payments_df['payment_date'] = pd.to_datetime(payments_df['payment_date'])

# 2021年のデータにフィルタリング
payments_2021 = payments_df[payments_df['payment_date'].dt.year == 2021]

# 最小日付と最大日付の設定
min_date = payments_2021['payment_date'].min().date()
max_date = payments_2021['payment_date'].max().date()

# Streamlitアプリケーションの設定
st.title('Payments in 2021')

# 日付フィルター
start_date = st.slider('selsect min date', min_value=min_date, max_value=max_date, value=min_date, format="YYYY-MM-DD")

end_date = st.slider('selsect max date', min_value=min_date, max_value=max_date, value=max_date, format="YYYY-MM-DD")

# フィルターの適用
filtered_data = payments_2021[(payments_2021['payment_date'] >= pd.to_datetime(start_date)) &
                              (payments_2021['payment_date'] <= pd.to_datetime(end_date))]

# 週単位でデータを集計
weekly_data = filtered_data.set_index('payment_date').resample('W-Mon').sum().reset_index().sort_values(by='payment_date')

# Matplotlibを使ってグラフを作成
fig, ax = plt.subplots(figsize=(7,4))
ax.plot(weekly_data['payment_date'], weekly_data['amount_spent'], label='Amount Spent')


# 凡例の追加
ax.legend(loc='center left', bbox_to_anchor=(1, 1))
ax.grid()
formatter = FuncFormatter(lambda x, _: f'{int(x):,}')
ax.yaxis.set_major_formatter(formatter)


# グラフを表示
st.pyplot(fig)
