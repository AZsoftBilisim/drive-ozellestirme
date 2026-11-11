
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If Parameters.Key.IsEmpty() Then
		UsingSeries = ProductsServer.SeriesIsSpecifiedCorrectly(
								Record.Warehouse,
								Record.Products,
								Record.Series,
								"SpecifyWhenPlanningShipment");
								
		FillPropertyValues(Record, UsingSeries);
		
		OnReadCreateAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	OnReadCreateAtServer();
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	ProductsOnChangeServer();
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	WhenChangingMeasurement();
EndProcedure

&AtClient
Procedure SeriesOnChange(Item)
	WhenChangingMeasurement();
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	WhenChangingMeasurement();
EndProcedure

&AtClient
Procedure AssignedByUserOnChange(Item)
	AssignedByUserOnChangeServer();
EndProcedure

&AtClient
Procedure StandardStockLevelOnChange(Item)
	UpdateCaptionExplanation();
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure ProductsOnChangeServer();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",     Record.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner" , Record.Package);

	StringStructure = New Structure;
	StringStructure.Insert("Products", Record.Products);
	StringStructure.Insert("Characteristic", Record.Characteristic);
	StringStructure.Insert("Package", Record.Package);
	StringStructure.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	BatchProcessingOfTablePartServer.ProcessTSString(StringStructure, StructureOfActions, Undefined);

	FillPropertyValues(Record, StringStructure);
	
	ItemVariantsAreUsed = StringStructure.ItemVariantsAreUsed;
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
	UsingSeries = ProductsServer.SeriesIsSpecifiedCorrectly(
													Record.Warehouse,
													Record.Products,
													Record.Series,
													"SpecifyWhenPlanningShipment");
	
	FillPropertyValues(Record, UsingSeries);
	
	Items.Series.Enabled = (Record.BatchesIndicationStatus <> 0);
	
	WhenChangingMeasurement();
EndProcedure

&AtServer
Procedure AssignedByUserOnChangeServer()
	If AssignedByUser = 1 Then
		Record.AssignedByUser = True;
	Else
		Record.AssignedByUser = False;
	EndIf;
	
	Items.StandardStockLevel.Enabled = Record.AssignedByUser;
	
	UpdateCaptionExplanation();
EndProcedure

&AtServer
Procedure WhenChangingMeasurement()
	Record.AverageDailyConsumption          = 0;		
	Record.RootMeanSquareVariance    = 0;			
	Record.ShipmentProbabilityWithinDay    = 0;			
	Record.Class			                 = Enums.XYZClassification.EmptyRef();
	StandardStockQuantityRecommended = 0;
	
	UpdateCaptionExplanation();
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure UpdateCaptionExplanation()
	
	If Record.AssignedByUser Then
		If Record.StandardStockLevel = 0 Then
			LabelText = NStr("vi = 'Đóng gói không tham gia vào chữ ký, vì đã chỉ ra giá trị định mức bằng 0.';
							|ru = 'Упаковка не участвует в подпитке, т.к. указано нулевое нормативное значение.';
							|en = 'Packaging unit is not used for replenishment as a zero value is specified.'; fa = 'Packaging unit is not used for replenishment as a zero value is specified.';
							|it = 'La confezione non partecipa all''approvvigionamento, dal momento che è specificato zero come valore standard.';
							|pl = 'Opakowanie nie uczestniczy w podładowaniu, ponieważ podano zerową wartość normatywną.';
							|tr = 'Sıfır standart değeri belirtildiği için paketleme ünitesi, stok yenilemeye dahil değildir.'");
		Else
			LabelText = NStr("vi = 'Đóng gói tham gia vào chữ ký, vì giá trị định mức được chỉ ra thủ công.';
							|ru = 'Упаковка участвует в подпитке, т.к. нормативное значение указано вручную.';
							|en = 'Packaging unit is used for replenishment as the standard value is set manually.'; fa = 'Packaging unit is used for replenishment as the standard value is set manually.';
							|it = 'La confezione partecipa all''approvvigionamento, dal momento che il valore standard è specificato manualmente.';
							|pl = 'Opakowanie uczestniczy w podładowaniu, ponieważ podano zerową wartość normatywną.';
							|tr = 'Standart değer manuel olarak girildiği için paketleme ünitesi stok yenilemeye dahildir.'");
		EndIf;
	ElsIf Not ValueIsFilled(Record.Class) Then
		LabelText = NStr("vi = 'Đóng gói không tham gia vào chữ ký, vì không tính đến các tham số dự báo.';
						|ru = 'Упаковка не участвует в подпитке, т.к. не рассчитаны параметры прогноза.';
						|en = 'Packaging unit is not used for replenishment as the forecast parameters are not calculated.'; fa = 'Packaging unit is not used for replenishment as the forecast parameters are not calculated.';
						|it = 'La confezione non partecipa all''approvvigionamento, dal momento che i parametri di previsione non sono calcolati.';
						|pl = 'Opakowanie uczestniczy w podładowaniu, ponieważ parametry prognozy nie są obliczane.';
						|tr = 'Tahmin parametreleri hesaplanmadığından paketleme ünitesi stok yenilemeye dahil değildir.'");
	ElsIf Record.ShipmentProbabilityWithinDay < MinimumProbabilityOfShipment Then
		LabelText = NStr("vi = 'Đóng gói không tham gia vào chữ ký, vì xác suất giao hàng trong ngày nhỏ hơn xác suất tối thiểu (%MinimumProbability%%) đã đặt trong tùy chỉnh chữ ký.';
						|ru = 'Упаковка не участвует в подпитке, т.к. вероятность отгрузки в течение дня меньше минимальной (%MinimumProbability%%), заданной в настройках подпитки.';
						|en = 'Packaging unit is not used for replenishment as the shipment probability during the day is less than the minimum value (%MinimumProbability%%) specified in the replenishment settings.'; fa = 'Packaging unit is not used for replenishment as the shipment probability during the day is less than the minimum value (%MinimumProbability%%) specified in the replenishment settings.';
						|it = 'La confezione non partecipa all''approvvigionamento, poiché la possibilità di spedizioni in giornata è sotto la soglia minima (%MinimumProbability% %), indicata nelle impostazioni dell''approvvigionamento.';
						|pl = 'Opakowanie nie uczestniczy w podładowaniu, ponieważ prawdopodobieństwo wysyłki w ciągu dnia jest mniejsze, niż minimum (%MinimumProbability%%), co określone w ustawieniach podładowania.';
						|tr = 'Gün içerisinde sevkiyat olasılığı, stok yenileme ayarlarında belirtilen minimum değerin (%MinimumProbability%%) altında olduğundan, paketleme üniteleri stok yenilemeye dahil değildir.'");
		LabelText = StrReplace(LabelText,"%MinimumProbability%", String(MinimumProbabilityOfShipment));
	Else
		LabelText = NStr("vi = 'Đóng gói tham gia vào chữ ký, vì xác suất giao hàng trong ngày lớn hơn xác suất tối thiếu (%MinimumProbability%%) đã đặt trong tùy chỉnh chữ ký.';
						|ru = 'Упаковка участвует в подпитке, т.к. вероятность отгрузки в течение дня больше минимальной (%MinimumProbability%%), заданной в настройках подпитки.';
						|en = 'Packaging unit is used for replenishment as the shipment probability during the day is higher than minimum value (%MinimumProbability%%) specified in the replenishment settings.'; fa = 'Packaging unit is used for replenishment as the shipment probability during the day is higher than minimum value (%MinimumProbability%%) specified in the replenishment settings.';
						|it = 'La confezione non partecipa all''approvvigionamento, perché la possibilità di spedizioni in giornata è sotto la soglia minima (%MinimumProbability%%), indicata nelle impostazioni dell''approvvigionamento.';
						|pl = 'Opakowanie uczestniczy w podładowaniu, ponieważ prawdopodobieństwo wysyłki w ciągu dnia jest mniejsze, niż minimum (%MinimumProbability%%), co określone w ustawieniach podładowania.';
						|tr = 'Gün içerisinde sevkiyat olasılığı, stok yenileme ayarlarında belirtilen minimum değerin (%MinimumProbability%%) üzerinde olduğundan, paketleme üniteleri stok yenilemeye dahildir.'");
		LabelText = StrReplace(LabelText,"%MinimumProbability%", String(MinimumProbabilityOfShipment));
	EndIf;		
	
	Items.DecorationNote.Title = LabelText;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Record.Warehouse));
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Record.Products);
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	Items.StandardStockLevel.Enabled = Record.AssignedByUser;
	Items.Series.Enabled = (Record.BatchesIndicationStatus <> 0);
	
	If Record.AssignedByUser Then
		AssignedByUser = 1;
	Else
		AssignedByUser = 0;
	EndIf;
	If Record.AssignedByUser Then
		AssignedByUser = 1;
	Else
		AssignedByUser = 0;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SettingsOfBinLocationWarehouses.MinimumProbabilityOfShipment AS MinimumProbabilityOfShipment,
	|	SettingsOfBinLocationWarehouses.ServiceLevelOfClassXPackages AS ServiceLevelX,
	|	SettingsOfBinLocationWarehouses.ServiceLevelOfClassZPackages AS ServiceLevelZ,
	|	SettingsOfBinLocationWarehouses.ServiceLevelOfClassYPackages AS ServiceLevelY
	|FROM
	|	InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
	|WHERE
	|	SettingsOfBinLocationWarehouses.Warehouse = &Warehouse
	|	AND SettingsOfBinLocationWarehouses.Premise = &Premise";
	Query.SetParameter("Warehouse", Record.Warehouse);
	Query.SetParameter("Premise", Record.Premise);
	
	Selection = Query.Execute().Select();
	
	Selection.Next();
	
	MinimumProbabilityOfShipment = Selection.MinimumProbabilityOfShipment;
	
	If Record.Class = Enums.XYZClassification.XClass Then
		StandardStockQuantityRecommended = Record.AverageDailyConsumption 
												 + Record.RootMeanSquareVariance
												 * Classification.GetServiceLevelFactor(Selection.ServiceLevelX);
	ElsIf Record.Class = Enums.XYZClassification.YClass Then
		StandardStockQuantityRecommended = Record.AverageDailyConsumption 
												 + Record.RootMeanSquareVariance
												 * Classification.GetServiceLevelFactor(Selection.ServiceLevelY);
	ElsIf Record.Class = Enums.XYZClassification.ZClass Then
		StandardStockQuantityRecommended = Record.AverageDailyConsumption 
												 + Record.RootMeanSquareVariance
												 * Classification.GetServiceLevelFactor(Selection.ServiceLevelZ);
	Else
		StandardStockQuantityRecommended = 0;
	EndIf;
	
	UpdateCaptionExplanation();
EndProcedure

#EndRegion

#EndRegion
