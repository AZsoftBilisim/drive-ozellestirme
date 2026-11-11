#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	For Each ArrRow In ThisObject Do
		ArrRow.AnalysisDepth                     = Metadata.InformationRegisters.SettingsOfBinLocationWarehouses.Resources.AnalysisDepth.FillValue;
		ArrRow.MinimumProbabilityOfShipment     = Metadata.InformationRegisters.SettingsOfBinLocationWarehouses.Resources.MinimumProbabilityOfShipment.FillValue;
		ArrRow.ServiceLevelOfClassXPackages = Metadata.InformationRegisters.SettingsOfBinLocationWarehouses.Resources.ServiceLevelOfClassXPackages.FillValue;
		ArrRow.ServiceLevelOfClassZPackages = Metadata.InformationRegisters.SettingsOfBinLocationWarehouses.Resources.ServiceLevelOfClassZPackages.FillValue;
		ArrRow.ForecastPackageConsumption = Metadata.InformationRegisters.SettingsOfBinLocationWarehouses.Resources.ForecastPackageConsumption.FillValue;
	EndDo;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	CurrentObject = ThisObject[0];
	
	NotCheckedAttributeArray.Add("WarehouseZoneFilter");
	NotCheckedAttributeArray.Add("LimitationByWeightFilter");
	NotCheckedAttributeArray.Add("LimitationByVolumeFilter");
			
	If CurrentObject.ConfigureGenerationByWarehouseAreas = "ByASingleWarehouseZone" 
		And Not ValueIsFilled(CurrentObject.WarehouseZoneFilter) Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Khu vực làm việc"" để tạo nhiệm vụ lấy ra.';
							|ru = 'Поле ""Рабочий участок"" для создания заданий на отбор не заполнено.';
							|en = '""Warehouse area"" field used to create filter jobs is not filled in.'; fa = '""Warehouse area"" field used to create filter jobs is not filled in.';
							|it = 'Il campo ""Area di lavoro"" per la creazione di attività di selezione non è compilato.';
							|pl = 'Pole ""Obszar roboczy"" do utworzenia zadań do wyboru nie jest wypełnione.';
							|tr = 'Filtre görevleri oluşturmak için ""Çalışma alanı"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(MessageText,, "WarehouseZoneFilter", "Record", Cancel);
		
	EndIf;
	
	If CurrentObject.LimitByWeightFilter
		And Not ValueIsFilled(CurrentObject.LimitationByWeightFilter)
		And (Not CurrentObject.ConfigureGenerationByWarehouseAreas = "GroupByWarehouseZones") Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Hạn chế theo trọng lượng"" để tạo nhiệm vụ lấy ra.';
							|ru = 'Поле ""Ограничение по весу"" для создания заданий на отбор не заполнено.';
							|en = '""Weight limit"" field used to create filter jobs is not filled in.'; fa = '""Weight limit"" field used to create filter jobs is not filled in.';
							|it = 'Il campo ""Limite di peso"" per la creazione di attività di selezione non è compilato.';
							|pl = 'Pole ""Ograniczenie wagi"" do tworzenia zadań selekcji nie jest zakończone.';
							|tr = 'Filtre görevleri oluşturmak için ""Ağırlık sınırı"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(MessageText,, "LimitationByWeight", "Record", Cancel);
		
	EndIf;
	
	If CurrentObject.LimitByVolumeFilter
		And Not ValueIsFilled(CurrentObject.LimitationByVolumeFilter)
		And (Not CurrentObject.ConfigureGenerationByWarehouseAreas = "GroupByWarehouseZones") Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Hạn chế theo khối lượng"" để tạo nhiệm vụ lấy ra.';
							|ru = 'Поле ""Ограничение по объему"" для создания заданий на отбор не заполнено.';
							|en = '""Limitation on volume"" field used to create filter jobs is not filled in.'; fa = '""Limitation on volume"" field used to create filter jobs is not filled in.';
							|it = 'Il campo ""Limite volume"" per la creazione di attività di selezione non è compilato.';
							|pl = 'Pole ""Ograniczenie ilości"" do utworzenia zadań do wyboru nie jest wypełnione.';
							|tr = 'Filtre görevleri oluşturmak için ""Hacim sınırı"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(MessageText,, "LimitationByVolume", "Record", Cancel);
		
	EndIf;
	
 	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure
	
#EndRegion
#EndIf
#EndIf