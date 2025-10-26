// import 'package:flutter/widgets.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:idev_viewer/src/internal/repo/home_repo.dart';
// import 'package:pluto_layout/pluto_layout.dart';
// import 'package:idev_viewer/src/internal/layout/menus/tree/system_menu.dart';
// import 'package:animated_tree_view/animated_tree_view.dart';
// import '../../pms/model/menu.dart';
// import 'package:idev_viewer/src/internal/pms/model/user_role.dart';
// import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
// import 'package:idev_viewer/src/internal/pms/usecase/menu_uc.dart';
// import 'package:idev_viewer/src/internal/pms/usecase/user_role_uc.dart';
// import 'package:idev_viewer/src/internal/pms/view/menu_v.dart';

// class LeftTab extends StatefulWidget {
//   const LeftTab({super.key});

//   @override
//   State<LeftTab> createState() => _LeftTabState();
// }

// class _LeftTabState extends State<LeftTab> {
//   bool isLoaded = false;
//   Map<String, dynamic> isSelected = {};
//   // List<TreeNode> menuTree = [];
//   late List<UserRole> myRole;
//   late HomeRepo homeRepo;

//   @override
//   void initState() {
//     homeRepo = context.read<HomeRepo>();

//     // userRepository.spikeId!
//     getUserRole('22n1101EFjMeBez9J').then((value) {
//       getUserMenu('22n1101EFjMeBez9J').then((value) {
//         setState(() {
//           homeRepo.menuTree;
//           isLoaded = true;
//         });
//       });
//     });

//     super.initState();
//   }

//   Future<void> getUserRole(String userId) async {
//     await sl<UserRoleUC>().get(userId: userId).then((result) {
//       result.when(
//           success: (success) {
//             myRole = success;
//             // userRepository.setUserMetaData(userRepository.getUserMetaData.copyWith(myRole: myRole));
//           },
//           error: (error) {});
//     });
//   }

//   Future<void> getUserMenu(String userId) async {
//     await sl<MenuUC>().get('9').then((result) {
//       result.when(
//           success: (success) {
//             success[0].menus?.forEach((child) {
//               homeRepo.menuTree.add(buildTree(
//                   TreeNode(key: '${child.menuId}', data: child),
//                   child, {}));
//             });
//           },
//           error: (error) {});
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return !isLoaded
//         ? const SizedBox()
//         : PlutoLayoutTabs(
//       // mode: PlutoLayoutTabMode.showSelected,
//       draggable: true,
//       tabViewSizeResolver: const PlutoLayoutTabViewSizeConstrains(
//         minSize: 100,
//         initialSize: 260,
//       ),
//       items:
//         homeRepo.menuTree.map((node) {
//           return PlutoLayoutTabItem(
//             id: '${(node.data as Menu).menuId}',
//             title: '${(node.data as Menu).menuNm}',
//             sizeResolver: const PlutoLayoutTabItemSizeInitial(300),
//             tabViewWidget: SystemMenu(menuTree: node),
//           );
//         }).toList()
//     );
//   }
// }
