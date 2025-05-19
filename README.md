# monitor_node
solana rpc node monitor
监控本地rpc点击是否掉块，方法是比较本地节点的slots和其他rpc节点slot，每隔5s采样一次。

<img width="784" alt="image" src="https://github.com/user-attachments/assets/3068415b-5443-4f1c-9f52-502925f05e66" />

PUBLIC_RPC_URL里的https://api.mainnet-beta.solana.com 要换成私有的比如helius、quicknode这种私有rpc，都有免费额度，足够用了
公共的rpc节点有时候波动大

local：本地rpc节点 slot
public: 对标的rpc节点slot
diff：差值，-1 掉一个，+1超前一个，0 表示同步。由于网络延迟，个位数的差异都可以忽略不计。

```
运行: ./m.sh
它自动开启进程保护，关了terminal也不会断
关闭是: pkill -f m.sh
查看日志：tail -f solana_monitor.log
```
