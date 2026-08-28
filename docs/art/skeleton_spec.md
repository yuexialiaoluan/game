# Character Skeleton 规范

## 定位
角色骨架仍然是 2D 部件骨架，不因世界 3D 化而改为 3D 骨骼。骨骼负责局部变换与装备挂载，最终作为 3D 世界中的 billboard 呈现。

## 基础骨骼节点
Root、Body、Head、Arm_L、Arm_R、Hand_L、Hand_R、Leg_L、Leg_R。
可扩展：Cape、Back、Weapon、Shield 等挂点。

## 装备挂点
- MainHand → Hand_R
- OffHand → Hand_L
- Helmet → Head
- Cape → Body

## 约束
- 不把骨骼数量硬编码成不可修改的系统。
- 不同种族可拥有不同骨架或骨骼比例，为 Retargeting 预留。

## 组成
- `Skeleton`：骨骼层级与比例。
- `Bone`：单块骨骼/挂点。
- `Bone Attachment`：骨骼挂点。
- `Bone Transform`：局部/全局变换。
- `Sprite Part`：绑定到骨骼的部件。
- `Equipment Attachment`：装备挂点。

## 存储
- 骨架定义放 `assets/characters/skeletons/`。
