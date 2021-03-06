///
/// [Author] Alex (https://github.com/AlexVincent525)
/// [Date] 2020/3/20 10:02
///
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:openjmu/constants/constants.dart';

/// [ChangeNotifier] for photo selector.
/// 图片选择器的 provider model
class PhotoSelectorProvider extends ChangeNotifier {
  /// Call [getAssetList] when constructing.
  /// 构造时开始获取资源
  PhotoSelectorProvider({
    this.maxAssets = 9,
    this.pathThumbSize = 80,
    Set<AssetEntity> selectedAssets,
  }) {
    if (selectedAssets?.isNotEmpty ?? false) {
      _selectedAssets = Set<AssetEntity>.from(selectedAssets);
    }
    getAssetList();
  }

  /// Maximum count for asset selection.
  /// 资源选择的最大数量
  final int maxAssets;

  /// Thumb size for path selector.
  /// 路径选择器中缩略图的大小
  final int pathThumbSize;

  /// Clear all fields when dispose.
  /// 销毁时重置所有内容
  @override
  void dispose() {
    _isAssetsEmpty = false;
    _isSwitchingPath = false;
    _pathEntityList.clear();
    _currentPathEntity = null;
    _currentAssets = null;
    _selectedAssets.clear();
    super.dispose();
  }

  /// Whether there's any assets on the devices.
  /// 设备上是否有资源文件
  bool _isAssetsEmpty = false;

  bool get isAssetsEmpty => _isAssetsEmpty;

  set isAssetsEmpty(bool value) {
    assert(value != null);
    if (value == _isAssetsEmpty) return;
    _isAssetsEmpty = value;
    notifyListeners();
  }

  /// Whether there's any assets that can be displayed;
  /// 是否有资源可供显示
  bool _hasAssetsToDisplay = false;

  bool get hasAssetsToDisplay => _hasAssetsToDisplay;

  set hasAssetsToDisplay(bool value) {
    assert(value != null);
    if (value == _hasAssetsToDisplay) return;
    _hasAssetsToDisplay = value;
    notifyListeners();
  }

  /// If path switcher was opened.
  /// 是否正在进行路径选择
  bool _isSwitchingPath = false;

  bool get isSwitchingPath => _isSwitchingPath;

  set isSwitchingPath(bool value) {
    assert(value != null);
    if (value == _isSwitchingPath) return;
    _isSwitchingPath = value;
    notifyListeners();
  }

  /// Map for all path entity.
  /// 所有包含资源的路径里列表
  ///
  /// Using [Map] in order to save the thumb data for the first asset under the path.
  /// 使用[Map]来保存路径下第一个资源的缩略数据。
  Map<AssetPathEntity, Uint8List> _pathEntityList = <AssetPathEntity, Uint8List>{};

  Map<AssetPathEntity, Uint8List> get pathEntityList => _pathEntityList;

  /// Path entity currently using.
  /// 正在查看的资源路径
  AssetPathEntity _currentPathEntity;

  AssetPathEntity get currentPathEntity => _currentPathEntity;

  set currentPathEntity(AssetPathEntity value) {
    assert(value != null);
    if (value == _currentPathEntity) return;
    _currentPathEntity = value;
    notifyListeners();
  }

  /// Assets under current path entity.
  /// 正在查看的资源路径下的所有资源
  Set<AssetEntity> _currentAssets;

  Set<AssetEntity> get currentAssets => _currentAssets;

  set currentAssets(Set<AssetEntity> value) {
    assert(value != null);
    if (value == _currentAssets) return;
    _currentAssets = value;
    notifyListeners();
  }

  /// Selected assets.
  /// 已选中的资源
  Set<AssetEntity> _selectedAssets = <AssetEntity>{};

  Set<AssetEntity> get selectedAssets => _selectedAssets;

  set selectedAssets(Set<AssetEntity> value) {
    assert(value != null);
    if (value == _selectedAssets) return;
    _selectedAssets = value;
    notifyListeners();
  }

  /// 选中图片是否为空
  bool get isSelectedNotEmpty => selectedAssets.isNotEmpty;

  /// Get assets path entities.
  /// 获取所有的资源路径
  Future<void> getAssetList() async {
    final List<AssetPathEntity> _list =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    for (final AssetPathEntity pathEntity in _list) {
      _pathEntityList[pathEntity] = await getFirstThumbFromPathEntity(pathEntity);
    }
    if (_pathEntityList.isNotEmpty) {
      _currentPathEntity = pathEntityList.keys.elementAt(0);
      await _currentPathEntity.refreshPathProperties();
      unawaited(getAssetsFromEntity(currentPathEntity));
    } else {
      isAssetsEmpty = true;
    }
  }

  /// Get assets under the specific path entity.
  /// 获取指定路径下的资源
  Future<void> getAssetsFromEntity(AssetPathEntity pathEntity) async {
    _currentAssets = (await pathEntity.getAssetListPaged(0, pathEntity.assetCount)).toSet();
    _hasAssetsToDisplay = currentAssets?.isNotEmpty ?? false;
    notifyListeners();
  }

  /// Get thumb data from the first asset under the specific path entity.
  /// 获取指定路径下的第一个资源的缩略数据
  Future<Uint8List> getFirstThumbFromPathEntity(AssetPathEntity pathEntity) async {
    final AssetEntity asset = (await pathEntity.getAssetListRange(start: 0, end: 1)).elementAt(0);
    final Uint8List assetData = await asset.thumbDataWithSize(pathThumbSize, pathThumbSize);
    return assetData;
  }

  /// Select asset.
  /// 选中资源
  void selectAsset(AssetEntity item) {
    if (selectedAssets.length == maxAssets) return;
    final Set<AssetEntity> _set = Set<AssetEntity>.from(selectedAssets);
    _set.add(item);
    selectedAssets = _set;
  }

  /// Un-select asset.
  /// 取消选中资源
  void unSelectAsset(AssetEntity item) {
    final Set<AssetEntity> _set = Set<AssetEntity>.from(selectedAssets);
    _set.remove(item);
    selectedAssets = _set;
  }

  /// Switch path entity.
  /// 切换路径
  void switchPath(AssetPathEntity pathEntity) {
    _isSwitchingPath = false;
    _currentPathEntity = pathEntity;
    notifyListeners();
    getAssetsFromEntity(currentPathEntity);
  }
}

/// [ChangeNotifier] for photo selector's viewer.
/// 图片选择查看器的 provider model.
class PhotoSelectorViewerProvider extends ChangeNotifier {
  /// Copy selected assets for editing when constructing.
  /// 构造时深拷贝已选择的图片集合，用于后续编辑。
  PhotoSelectorViewerProvider(Set<AssetEntity> assets) {
    _currentlySelectedAssets = Set<AssetEntity>.from(assets);
  }

  /// Selected assets in viewer.
  /// 查看器中已选择的资源
  Set<AssetEntity> _currentlySelectedAssets;

  Set<AssetEntity> get currentlySelectedAssets => _currentlySelectedAssets;

  set currentlySelectedAssets(Set<AssetEntity> value) {
    assert(value != null);
    if (value == _currentlySelectedAssets) return;
    _currentlySelectedAssets = value;
    notifyListeners();
  }

  /// 选中图片是否为空
  bool get isSelectedNotEmpty => currentlySelectedAssets?.isNotEmpty ?? false;

  /// Select asset.
  /// 选中资源
  void selectAssetEntity(AssetEntity entity) {
    final Set<AssetEntity> set = Set<AssetEntity>.from(currentlySelectedAssets);
    set.add(entity);
    currentlySelectedAssets = Set<AssetEntity>.from(set);
  }

  /// Un-select asset.
  /// 取消选中资源
  void unSelectAssetEntity(AssetEntity entity) {
    final Set<AssetEntity> set = Set<AssetEntity>.from(currentlySelectedAssets);
    set.remove(entity);
    currentlySelectedAssets = Set<AssetEntity>.from(set);
  }
}
