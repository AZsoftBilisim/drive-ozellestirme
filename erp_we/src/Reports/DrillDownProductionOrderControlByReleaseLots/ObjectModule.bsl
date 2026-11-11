#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	SetOfLaunchLotReferences = DataCompositionSchema.DataSets.LaunchParties;

	ProductionManagement.SubstitutionOfActualRegisterOfGraph(SetOfLaunchLotReferences.Query);

	DataCompositionClientServer.SetParameter(SettingsComposer, "TextIsPlanned", NStr("vi = 'Đã dự tính';
																					|ru = 'Запланировано';
																					|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
																					|it = 'Scheduled';
																					|pl = 'Scheduled';
																					|tr = 'Planlandı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TextRunning", NStr("vi = 'Đã khởi động';
																					|ru = 'Запущено';
																					|en = 'Started'; fa = 'شروع‌شده';
																					|it = 'Started';
																					|pl = 'Started';
																					|tr = 'Başlatıldı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TextWithoutBillOfMaterials", NStr("vi = '<Không có bảng kê chi tiết>';
																									|ru = '<Без спецификации>';
																									|en = '<Without bill of materials>'; fa = '<Without bill of materials>';
																									|it = '<Without bill of materials>';
																									|pl = '<Without bill of materials>';
																									|tr = '<Ürün reçetesiz>'"));
EndProcedure

#EndRegion

#EndIf