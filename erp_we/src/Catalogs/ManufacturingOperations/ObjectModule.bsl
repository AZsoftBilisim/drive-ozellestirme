#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ValuesOfRCDetails = ValuesOfRCDetails();
	
	ExcludeFromVerification = New ValueList();
	ExcludeFromVerification.Add("SetupSettings",, ContainsNestedRoute Or ContainsTechnologicalProcess Or Not ValuesOfRCDetails.SetupSettingsAreUsed);
	ExcludeFromVerification.Add("Load",, ContainsNestedRoute Or ContainsTechnologicalProcess Or Not ValuesOfRCDetails.ParallelLoad);
	ExcludeFromVerification.Add("NestedRoute",, Not ContainsNestedRoute);
	ExcludeFromVerification.Add("TechnologicalProcess",, Not ContainsTechnologicalProcess);
	ExcludeFromVerification.Add("TechnologicalProcessFactor",, Not ContainsTechnologicalProcess);
	ExcludeFromVerification.Add("Control",, ContainsNestedRoute Or ContainsTechnologicalProcess Or Not GetFunctionalOption("UseOperationExecutionControl"));
	
	OnlyVerificationOfAdditionalDetails = AdditionalProperties.Property("SpecificationStatus_")
		And AdditionalProperties.SpecificationStatus_ <> Enums.BOMStatuses.Valid;
	
	NotCheckedAttributeArray = New Array;
	For Each Item In ExcludeFromVerification Do
		If Item.Check Or OnlyVerificationOfAdditionalDetails Then
			NotCheckedAttributeArray.Add(Item.Value);
		EndIf;
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If OnlyVerificationOfAdditionalDetails Then
		Return; // only verification of additional details
	EndIf;
	
	CheckAttributesFilling(Cancel);
	
EndProcedure

Procedure CheckAttributesFilling(Cancel, Name_Stage = "") Export
	
	If OperationNumber >= NextOperation 
		And NextOperation <> 0 Then
		
		If ValueIsFilled(Name_Stage) Then
			MessageText = StrTemplate(NStr("vi = 'Số giao dịch tiếp theo cần phải lớn hơn số giao dịch (công đoạn: %2, giao dịch: %3).';
											|ru = 'Номер следующей операции должен быть больше номера операции (этап: %2, операция: %3).';
											|en = 'The next operation number must be greater than the operation number (stage: %2, operation: %3).'; fa = 'The next operation number must be greater than the operation number (stage: %2, operation: %3).';
											|it = 'Il numero della prossima operazione deve essere maggiore del numero dell''operazione (fase: %2, operazione: %3).';
											|pl = 'Numer następnej operacji powinien być większy niż numer operacji (etap: %2, operacja: %3).';
											|tr = 'Sonraki işlem numarası, işlem numarasından büyük olmalıdır (aşama: %2, işlem: %3).'"),
				Name_Stage, Description);
		Else
			MessageText = NStr("vi = 'Số giao dịch sau phải lớn hơn số giao dịch.';
								|ru = 'Номер следующей операции должен быть больше номера операции.';
								|en = 'Number of the next operation should be greater than the operation number.'; fa = 'Number of the next operation should be greater than the operation number.';
								|it = 'Il numero della prossima operazione deve essere maggiore del numero dell''operazione.';
								|pl = 'Numer kolejnej operacji musi być większy od numeru operacji.';
								|tr = 'Sonraki işlem numarası, işlem numarasından büyük olmalıdır.'");
		EndIf;
		Common.MessageToUser(MessageText, ThisObject, "NextOperation",, Cancel);
		
	EndIf; 
	
	If ValueIsFilled(WorkCenter) Then
		
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters") Then
		
			BankingDetailsWorkCenter = Common.ObjectAttributesValues(WorkCenter, "WorkCenterType.ParallelLoad, MaximumLoad");
			
			If BankingDetailsWorkCenter.WorkCenterTypeParallelLoad 
				And Load > BankingDetailsWorkCenter.MaximumLoad  Then
				
				If ValueIsFilled(Name_Stage) Then
					MessageText = StrTemplate(NStr("vi = 'Kết nhập thao tác vượt quá số lần kết nhập tối đa nguồn lực sản xuất (công đoạn: %2, thao tác: %3).';
													|ru = 'Загрузка операции превышает максимальную загрузку рабочего центра (этап: %2, операция: %3).';
													|en = 'Operation load exceeds maximum work center load (stage: %2, operation: %3).'; fa = 'Operation load exceeds maximum work center load (stage: %2, operation: %3).';
													|it = 'Il carico dell''operazione supera il carico massimo del centro di lavoro (fase: %2, operazione: %3).';
													|pl = 'Pobieranie operacji przekracza maksymalne obciążenia centrum wykonania pracy (etap: %2, operacja: %3).';
													|tr = 'İşlemin çalışma yükü, iş merkezinin maksimum çalışma yükünü aşmaktadır (aşama: %2, işlem: %3).'"),
						Name_Stage, Description);
				Else
					MessageText = NStr("vi = 'Kết nhập thao tác đã vượt quá số lần kết nhập tối đa của nguồn lực sản xuất.';
										|ru = 'Загрузка операции превышает максимальную загрузку рабочего центра.';
										|en = 'Operation load exceeds the maximum work center load.'; fa = 'Operation load exceeds the maximum work center load.';
										|it = 'Il download dell''operazione supera il carico massimo del centro di lavoro.';
										|pl = 'Pobieranie operacji przekracza maksymalne pobieranie centrum pracy.';
										|tr = 'İşlemin çalışma yükü, iş merkezinin maksimum çalışma yükünü aşmaktadır.'");
				EndIf;
				Common.MessageToUser(MessageText, ThisObject, "Load",, Cancel);
				
			EndIf;
			
		EndIf;
		
		If AuxiliaryWorkCenters.Count() > 0 Then
			
			QueryText = "
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	Catalog.WorkCenters AS MainWorkCenters
			|WHERE
			|	(MainWorkCenters.Ref = &MainWorkCenter
			|		OR MainWorkCenters.WorkCenterType = &MainWorkCenter)
			|	AND TRUE IN (
			|			SELECT TOP 1
			|				TRUE
			|			FROM 
			|				Catalog.WorkCenters AS AuxiliaryWorkCenters
			|			WHERE
			|				(AuxiliaryWorkCenters.Ref IN (&AuxiliaryWorkCenters)
			|					OR AuxiliaryWorkCenters.WorkCenterType IN (&AuxiliaryWorkCenters))
			|				AND MainWorkCenters.Ref = AuxiliaryWorkCenters.Ref)
			|";
			
			Query = New Query(QueryText);
			Query.SetParameter("MainWorkCenter",         WorkCenter);
			Query.SetParameter("AuxiliaryWorkCenters", AuxiliaryWorkCenters.UnloadColumn("WorkCenter"));
			
			If Not Query.Execute().IsEmpty() Then
				
				MessageText = NStr("vi = 'Danh sách nguồn lực sản xuất phụ trợ cấm chỉ ra nguồn lực sản xuất (hoặc dạng nguồn lực sản xuất) trùng với nguồn lực sản xuất chính.';
									|ru = 'Списке вспомогательных рабочих центров запрещено указывать рабочий центр (либо вид рабочего центра), дублирующий основной рабочий центр.';
									|en = 'It is prohibited to specify a work center or a work center type duplicating the main work center in the auxiliary work center list.'; fa = 'It is prohibited to specify a work center or a work center type duplicating the main work center in the auxiliary work center list.';
									|it = 'All''elenco dei centri di lavoro di supporto è vietato indicare il centro di lavoro (o il tipo di centro di lavoro) duplicato del centro di lavoro principale.';
									|pl = 'Dla listy pomocniczych gniazd produkcyjnych jest zabronione określenie gniazda produkcyjnego (lub rodzaju gniazda produkcyjnego), duplikującego podstawowe gniazdo produkcyjne.';
									|tr = 'Yardımcı iş merkezleri listesinde, ana iş merkezini yineleyen bir iş merkezi (veya iş merkezi türü) belirtmek yasaktır.'");
				Common.MessageToUser(MessageText, ThisObject, "AuxiliaryWorkCenters",, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ProductionArea) And ValueIsFilled(WorkCenter) Then
		
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters") Then

			WorkCenterAttributes = Common.ObjectAttributeValue(WorkCenter, "ProductionArea");

			If ProductionArea <> WorkCenterAttributes Then

				MessageText = NStr("vi = 'Trường ""Khu vực"" khác với khu vực của nguồn lực sản xuất.';
									|ru = 'Поле ""Участок"" отличается от участка рабочего центра.';
									|en = '""Area"" field is different from the work center area.'; fa = '""Area"" field is different from the work center area.';
									|it = 'Il campo ""Sito"" differisce dal sito del centro di lavoro.';
									|pl = 'Pole ""Obszar"" różni się od obszaru gniazda produkcyjnego.';
									|tr = '""Saha"" alanı, iş merkezi sahasından farklıdır.'");
				Common.MessageToUser(MessageText, ThisObject, "ProductionArea", , Cancel);

			EndIf;
			
		EndIf;
		
	EndIf;
	
	AvailableTimeUnits = Catalogs.ManufacturingOperations.AvailableTimeUnits();
	MessageTemplate = NStr("vi = 'Đối với mục tin ""%1"" đã nhập sai giá trị đơn vị tính. Phương án hợp lệ là: ""giây"", ""phút"", ""giờ"", ""ngày"".';
							|ru = 'Для реквизита ""%1"" введено некорректное значение единицы измерения. Доступные варианты: ""секунда"", ""минута"", ""час"", ""сутки"".';
							|en = 'An incorrect unit of measure is specified for the ""%1"" item. Available options: ""second"", ""minute"", ""hour"", and ""day"".'; fa = 'An incorrect unit of measure is specified for the ""%1"" item. Available options: ""second"", ""minute"", ""hour"", and ""day"".';
							|it = 'An incorrect unit of measure is specified for the ""%1"" item. Available options: ""second"", ""minute"", ""hour"", and ""day"".';
							|pl = 'An incorrect unit of measure is specified for the ""%1"" item. Available options: ""second"", ""minute"", ""hour"", and ""day"".';
							|tr = '""%1"" özniteliği için birim değeri yanlış girilmiş. Mevcut seçenekler: ""saniye"", ""dakika"", ""saat"", ""gün"".'");
	
	If ValueIsFilled(TimePerPieceUnitOfMeasure)
		And AvailableTimeUnits.Find(TimePerPieceUnitOfMeasure) = Undefined Then
		MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Thời gian thực hiện';
														|ru = 'Время выполнения';
														|en = 'Execution time'; fa = 'زمان اجرا';
														|it = 'Tempo di esecuzione';
														|pl = 'Czas wykonania';
														|tr = 'Gerçekleştirme süresi'"));
		Common.MessageToUser(MessageText, ThisObject, "TimePerPieceUnitOfMeasure", , Cancel);
	EndIf;
	
	If ValueIsFilled(SetupTimeUnitOfMeasure)
		And AvailableTimeUnits.Find(SetupTimeUnitOfMeasure) = Undefined Then
		MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Thời gian PZ';
														|ru = 'Время ПЗ';
														|en = 'Setup time'; fa = 'زمان راه‌اندازی';
														|it = 'Tempo per eseguire i lavori preparatori e finali';
														|pl = 'Czas PK';
														|tr = 'HB süresi'"));
		Common.MessageToUser(MessageText, ThisObject, "SetupTimeUnitOfMeasure", , Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Owner.IsEmpty() Then
		Return;
	EndIf;
	
	OperationYouAreDeletingShouldNotBeUsedInRouteMap(Cancel);
	
	CheckLooping(Cancel);
	
	CheckStatusOfOwner(Cancel);
	
	FillInServiceDetails();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Id = 0;
	Basis = Undefined;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("Owner") Then
		OperationNumber = Catalogs.ManufacturingOperations.NewOperationNumber(FillingData.Owner);
		NextOperation = OperationNumber + 1;
	EndIf;	

EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure FillInServiceDetails() Export
	
	// When copying a route map, an alternative handler for creating a technological operation is executed
	//  See Catalogs.ManufacturingOperations.CopyProcessOperation.
	
	If Not ValueIsFilled(Id) Then
		Id = Catalogs.ManufacturingOperations.NewOperationID(Owner);
	EndIf;
	
	If TypeOf(Owner) = Type("CatalogRef.ProductionStages") Then
		BillOfMaterials = Common.ObjectAttributeValue(Owner, "Owner");
	Else
		BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
	EndIf;

EndProcedure

Procedure CheckLooping(Cancel)

	If Not ContainsNestedRoute Then
		Return;
	EndIf;
	
	If Catalogs.ManufacturingOperations.HasLoop(NestedRoute, Owner, Cancel) Then
		MessageText = NStr("vi = 'Các quy trình lồng nhau được chọn dẫn đến giao dịch lặp.';
							|ru = 'Выбранный вложенный маршрут приводит к зацикливанию операций.';
							|en = 'The selected nested route causes operation looping.'; fa = 'The selected nested route causes operation looping.';
							|it = 'Il percorso selezionato porta ad un ciclo di operazioni.';
							|pl = 'Wybrana trasa zagnieżdżona prowadzi do zapętlenia operacji.';
							|tr = 'Seçilen iç içe yol, işlemlerin döngüye girmesine neden olmaktadır.'");
		Common.MessageToUser(MessageText, Ref, "NestedRoute",, Cancel);
	EndIf; 
	
EndProcedure

Procedure CheckStatusOfOwner(Cancel)
	
	If Cancel Or Not IsNew() Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DoNotCheckStatusOfOwner") Then
		Return;
	EndIf;
	
	MessageTemplate = NStr("vi = '%1 có trạng thái ""Có hiệu lực"". Không thể thêm các giao dịch mới.';
							|ru = '%1 имеет статус ""Действует"". Добавление новых операций недоступно.';
							|en = '%1 has the Valid status. You cannot add new operations.'; fa = '%1 has the Valid status. You cannot add new operations.';
							|it = '%1 имеет статус ""Действует"". Добавление новых операций недоступно.';
							|pl = '%1 has the Valid status. You cannot add new operations.';
							|tr = '%1, ""Aktif"" durumuna sahiptir. Yeni işlemler eklenemez.'");
	
	If TypeOf(Owner) = Type("CatalogRef.RouteSheets") Then
		AttributePath1 = "Status";
		ValidStatus = Enums.StatusesOfRouteSheets.Valid;
		MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Sơ đồ quy trình';
														|ru = 'Маршрутная карта';
														|en = 'Route sheet'; fa = 'برگه مسیر';
														|it = 'Scheda di lavorazione';
														|pl = 'Karta technologiczna';
														|tr = 'Rota'"));
	ElsIf TypeOf(Owner) = Type("CatalogRef.TechnologicalProcesses") Then
		AttributePath1 = "Status";
		ValidStatus = Enums.TechnologicalProcessStatuses.Valid;
		MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Quy trình công nghệ';
														|ru = 'Технологический процесс';
														|en = 'Technological process'; fa = 'فرایند فناورانه';
														|it = 'Processo tecnologico';
														|pl = 'Proces technologiczny';
														|tr = 'Teknolojik süreç'"));
	ElsIf TypeOf(Owner) = Type("CatalogRef.ProductionStages") Then
		AttributePath1 = "Owner.Status";
		ValidStatus = Enums.BOMStatuses.Valid;
		MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Bảng kê chi tiết';
														|ru = 'Спецификация';
														|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
														|it = 'Спецификация';
														|pl = 'Bill of materials';
														|tr = 'Ürün reçetesi'"));
	Else
		Return;
	EndIf;
	
	OwnerStatus = Common.ObjectAttributeValue(Owner, AttributePath1);
	If OwnerStatus = ValidStatus Then
		Common.MessageToUser(MessageText, Owner,,,Cancel);
	EndIf;
	
EndProcedure

Function ValuesOfRCDetails()
	
	If ValueIsFilled(WorkCenter) Then
		
		AttributesNames = New Structure;
		AttributesNames.Insert("SetupSettingsAreUsed", "SetupSettingsAreUsed");
		AttributesNames.Insert("ParallelLoad", "ParallelLoad");
		
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters") Then
			For Each Item In AttributesNames Do
				AttributesNames[Item.Key] = "WorkCenterType." + Item.Value;
			EndDo;
		EndIf;
		
		Result = Common.ObjectAttributesValues(WorkCenter, AttributesNames);
		
	Else
		
		Result = New Structure;
		Result.Insert("SetupSettingsAreUsed", False);
		Result.Insert("ParallelLoad", False);
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure OperationYouAreDeletingShouldNotBeUsedInRouteMap(Cancel)

	If Not IsNew() And DeletionMark And Not Common.ObjectAttributeValue(Ref, "DeletionMark") Then
		
		Query = New Query;
		Query.Text = 
		"SELECT TOP 1
		|	RelationshipTable.Ref
		|FROM
		|	Catalog.RouteSheets.ManufacturedProducts AS RelationshipTable
		|WHERE
		|	RelationshipTable.OperationEdit = &Operation
		|	AND NOT RelationshipTable.Ref.DeletionMark
		|	AND RelationshipTable.Ref = &Owner";
		
		Query.SetParameter("Operation", Ref);
		Query.SetParameter("Owner", Owner);
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			MessageText = NStr("vi = 'Giao dịch được sử dụng trong bản đồ tuyến đường. Loại bỏ là không thể.';
								|ru = 'Операция используется в маршрутной карте. Удаление невозможно.';
								|en = 'The operation is used in the route sheet. Cannot remove it.'; fa = 'The operation is used in the route sheet. Cannot remove it.';
								|it = 'L''operazione viene utilizzata dalla scheda di lavorazione. Impossibile cancellarla.';
								|pl = 'Operacja jest używana w karcie technologicznej. Nie można usunąć.';
								|tr = 'İşlem, rotada kullanılmaktadır. Silinmesi mümkün değildir.'");
			Common.MessageToUser(MessageText, Ref,,, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
 
#EndRegion

#EndIf