#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Checks the filling in of the details stage
// Used when writing a valid specification and when editing a stage in a production order.
//
// Parameters:
//	ReportStageName_ - Boolean - if True the stage representation will be added to the error message text
//  DataPath     - String - data path (the path to the props of the form), is used to correct the output messages
//  Cancel 			- Boolean - true if errors are found.
//
// Returns:
//   Boolean   - True if filling errors are found.
//
Function CheckAttributesFilling(ReportStageName_, Val DataPath = "", Cancel = False) Export

	HasErrors = False;
	
	If DataPath = "" Then
		DataKey = ThisObject;
	Else
		DataKey = Undefined;
	EndIf;
	
	CheckHeaderDetails(DataKey, ReportStageName_, HasErrors, DataPath);
	
	If PlanOperationsOfWorkCenterTypes Then
		
		CheckFillingOfTypesOfWorkCenters(DataKey, ReportStageName_, HasErrors);
		
	EndIf;
	
	CheckIfStageDurationIsFilledIn(DataKey, ReportStageName_, HasErrors);
	
	If HasErrors Then
		Cancel = True;
	EndIf; 
	
	Return Not HasErrors;
	
EndFunction

// The procedure fills in the planned duration and the unit of measurement for the duration of the BBB stage.
//
Procedure FillInUnitOfMeasurementAndDurationOfBBVStage() Export
	
	ProductDataManagement.FillInUnitOfMeasurementAndDurationOfBBVStage(
		ThisObject, WorkCenterTypes, False);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	// These details are checked only when writing down the current specification
	NotCheckedAttributeArray.Add("Department");
	NotCheckedAttributeArray.Add("RouteSheetFactor");
	NotCheckedAttributeArray.Add("QuantityOfProductUnitsLotsProducedSimultaneously");
	NotCheckedAttributeArray.Add("WorkCenterTypes");
	NotCheckedAttributeArray.Add("WorkCenterTypes.WorkCenterType");
	NotCheckedAttributeArray.Add("WorkCenterTypes.OperationTime");
	NotCheckedAttributeArray.Add("WorkCenterTypes.UnitOfMeasure");
	NotCheckedAttributeArray.Add("WorkCenterTypes.SetupSettings");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	SpecificationStatus_ = Undefined;
	If Not AdditionalProperties.Property("SpecificationStatus_", SpecificationStatus_) Then
		SpecificationStatus_ = Common.ObjectAttributeValue(Owner, "Status");
	EndIf;
	
	If SpecificationStatus_ <> Enums.BOMStatuses.Valid Then
		Return; // only verification of additional details
	EndIf;
	
	If StageNumber >= NextStageNo And NextStageNo <> 0 Then
		MessageText = NStr("vi = 'Số công đoạn tiếp theo phải lớn hơn số công đoạn.';
							|ru = 'Номер следующего этапа должен быть больше номера этапа.';
							|en = 'Next stage number should be more than the stage number.'; fa = 'Next stage number should be more than the stage number.';
							|it = 'Il numero della fase successiva deve essere superiore al numero della fase.';
							|pl = 'Numer kolejnego etapu musi być większy niż numer etapu.';
							|tr = 'Sonraki işlem numarası, aşama numarasından büyük olmalıdır.'");
		Common.MessageToUser(MessageText, ThisObject, "NextStageNo",, Cancel);
	EndIf;
	
	If ProductionByThirdParty
		And SubcontractorServices.Count() > 1
		And Not GetFunctionalOption("UseProductionByThirdParty2_5") Then
		MessageText = NStr("vi = 'Chỉ có thể chỉ ra nhiều dịch vụ của bên nhận gia công khi bật ghi nhận theo phiên bản 2.5.';
							|ru = 'Указание нескольких услуг переработчика доступно только при включенном учете по версии 2.5.';
							|en = 'You can specify several subcontractor services only if accounting 2.5 is enabled.'; fa = 'You can specify several subcontractor services only if accounting 2.5 is enabled.';
							|it = 'Indicazione di alcuni servizi dell''elaboratore disponibile solo all''attivazione della versione 2.5 di contabilità.';
							|pl = 'Podanie kilku usług przetwórcy jest dostępne tylko przy włączonej ewidencji według wersji 2.5.';
							|tr = 'Birden fazla fason üretici hizmetinin belirtilmesi, sadece sürüm 2.5 üzerinden hesap etkinleştirildiğinde kullanılabilir.'");
		Common.MessageToUser(MessageText, ThisObject, "SubcontractorServices",, Cancel);
	EndIf;
	
	CheckAttributesFilling(False,, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	If PlanOperationsOfWorkCenterTypes Then
		
		For Each String In WorkCenterTypes Do
			If Not IsBlankString(String.QuantityCalculationAlgorithm) Then
				String.OperationTime = 0;
				NotUsedWorkCenterTypesWithFormulasAreUpdated = True;
			EndIf;
		EndDo;
		
		For Each String In AlternateWorkCenterTypes Do
			If Not IsBlankString(String.QuantityCalculationAlgorithm) Then
				String.OperationTime = 0;
			EndIf;
		EndDo;
		
		If WorkCenterTypes.Count() > 0 Then
			MainVRC = WorkCenterTypes[0].WorkCenterType;
		EndIf;
	Else
		
		WorkCenterTypes.Clear();
		AlternateWorkCenterTypes.Clear();
		
	EndIf;
	
	ProductionSettings = ProductionServerCached.SubsystemSettingsProduction();
	If ProductionProcessEditorClientServer.CalculateDurationAutomatically(ThisObject,
		ProductionSettings.ProductionIsUsed21,
		ProductionSettings.PlanningByMaterialResourcesIsUsed,
		ProductionSettings.PlanningByProductionResourcesIsUsed) Then
		FillInUnitOfMeasurementAndDurationOfBBVStage();
	EndIf; 
	
	NumberOfTypesOfRC = WorkCenterTypes.Count();
	
	If NumberOfTypesOfRC > 0 Then
		
		ViewsSettings = Common.ObjectsAttributesValues(WorkCenterTypes.UnloadColumn("WorkCenterType"), "ParallelLoad, ImportOption");
		
		For Each TSRow In WorkCenterTypes Do
			
			If Not TSRow.WorkCenterType.IsEmpty() Then
				SettingUpVRC = ViewsSettings.Get(TSRow.WorkCenterType);
				If SettingUpVRC.ParallelLoad Then
					If SettingUpVRC.ImportOption = Enums.WorkCenterLoadOptions.Synchronous Then
						TSRow.QuantityCalculationAlgorithm = "";
					EndIf;
					Continue;
				EndIf;
			EndIf;
			
		EndDo;
		
		If ProductionSettings.ProductionIsUsed21
			And NumberOfTypesOfRC > 1 And OperatingProcedureOfWorkCenterTypes.IsEmpty() Then
			
			OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Independently;
			
		ElsIf ProductionSettings.DynamicStructureOfProductionOrders
			And NumberOfTypesOfRC > 1 And OperatingProcedureOfWorkCenterTypes <> Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously Then
			
			OperatingProcedureOfWorkCenterTypes = ?(NumberOfTypesOfRC > 1, Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously, Enums.OperatingProcedureOfWorkCenterTypes.EmptyRef());
			MessageText = NStr("vi = 'Trong lập kế hoạch động, không cho phép thiết lập thứ tự làm việc của các dạng nguồn lực làm việc khác với ""Đồng thời"". Đã thiết lập lại tùy chọn hiện tại.';
								|ru = 'При динамическом планировании не допускается устанавливать порядок работы видов РЦ отличный от ""Одновременно"". Текущий вариант был сброшен.';
								|en = 'For dynamic planning, you cannot set the operating procedure of work center types other than ""Simultaneously"". The current option is reset.'; fa = 'For dynamic planning, you cannot set the operating procedure of work center types other than ""Simultaneously"". The current option is reset.';
								|it = 'При динамическом планировании не допускается устанавливать порядок работы видов РЦ отличный от ""Одновременно"". Текущий вариант был сброшен.';
								|pl = 'For dynamic planning, you cannot set the operating procedure of work center types other than ""Simultaneously"". The current option is reset.';
								|tr = 'Dinamik programlamada, İş Yeri türlerinin çalışma sırasının ""Eş zamanlı"" haricinde bir duruma ayarlanmasına izin verilmemektedir. Geçerli değişken sıfırlandı.'");
			Common.MessageToUser(MessageText, Ref);
			
		EndIf;
		
	EndIf;
	
	If AlternateWorkCenterTypes.Count() > 0 Then
		
		ViewsSettings = Common.ObjectsAttributesValues(AlternateWorkCenterTypes.UnloadColumn("WorkCenterType"), "ParallelLoad, ImportOption");
		
		For Each TSRow In AlternateWorkCenterTypes Do
			
			If Not TSRow.WorkCenterType.IsEmpty() Then
				SettingUpVRC = ViewsSettings.Get(TSRow.WorkCenterType);
				If SettingUpVRC.ParallelLoad Then
					If SettingUpVRC.ImportOption = Enums.WorkCenterLoadOptions.Synchronous Then
						TSRow.QuantityCalculationAlgorithm = "";
					EndIf;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	FillInServiceDetailsCached();
	
	If Not Owner.IsEmpty() And Not AdditionalProperties.Property("AllowRecording") Then
		
		// If the stage is deleted, then we will check that it is not used in the specification
		If Not IsNew()
			And DeletionMark
			And Not Common.ObjectAttributeValue(Ref, "DeletionMark") Then
			
			Query = New Query;
			Query.Text = 
			"SELECT TOP 1
			|	RelationshipTable.Ref
			|FROM
			|	Catalog.BillsOfMaterials.ManufacturedProducts AS RelationshipTable
			|WHERE
			|	RelationshipTable.StageEditing = &Stage
			|	AND RelationshipTable.Ref = &Owner
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	RelationshipTable.Ref
			|FROM
			|	Catalog.BillsOfMaterials.MaterialsAndServices AS RelationshipTable
			|WHERE
			|	RelationshipTable.StageEditing = &Stage
			|	AND RelationshipTable.Ref = &Owner
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	RelationshipTable.Ref
			|FROM
			|	Catalog.BillsOfMaterials.LaborCosts AS RelationshipTable
			|WHERE
			|	RelationshipTable.StageEditing = &Stage
			|	AND RelationshipTable.Ref = &Owner
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	RelationshipTable.Ref
			|FROM
			|	Catalog.BillsOfMaterials AS RelationshipTable
			|WHERE
			|	RelationshipTable.Ref = &Owner
			|	AND RelationshipTable.Status = VALUE(Enum.BOMStatuses.Valid)";
			
			Query.SetParameter("Stage",     Ref);
			Query.SetParameter("Owner", Owner);
			
			Result = Query.Execute();
			If Not Result.IsEmpty() Then
				MessageText = NStr("vi = 'Công đoạn được sử dụng trong bảng kê chi tiết các nguồn lực sản xuất. Không thể xóa.';
									|ru = 'Этап используется в спецификации. Удаление невозможно.';
									|en = 'Stage in used in the bill of materials. Deletion is impossible.'; fa = 'Stage in used in the bill of materials. Deletion is impossible.';
									|it = 'La fase è usata nella specifica. Impossibile eliminare.';
									|pl = 'Etap jest wykorzystywany w specyfikacji. Usunięcie nie jest możliwe.';
									|tr = 'Aşama, ürün reçetesinde kullanılmaktadır. Silinmesi mümkün değildir.'");
				Common.MessageToUser(MessageText, Ref,,, Cancel);
			EndIf; 
			
		EndIf; 
		
	EndIf;
	
	CheckStatusOfOwner(Cancel);
	
	If Not Cancel And ItIsNecessaryToCalculateDurationOfProduction() Then
		
		AdditionalProperties.Insert("CalculateProductionDuration");
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("Owner") Then
		
		Owner = FillingData.Owner;
		FillInNewObject();
		
	EndIf; 
	
	// We fill it in programmatically, because the unit of time is used in several places
	BasicBufferTimeUnit = Catalogs.ProductionStages.BasicBufferTimeUnit();
	UnitOfMeasureOfPreliminaryBuffer = BasicBufferTimeUnit;
	UnitOfMeasureOfFollowUpBuffer     = BasicBufferTimeUnit;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	FillInNewObject();
	
	ProductDataManagement.UpdateObjectLinkKeys(ThisObject, True);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("CalculateProductionDuration") Then
		
		InformationRegisters.JobsOfStandardProductionDurationCalculation.AddJob(Owner, True, True);
		
	EndIf;
	If ValueIsFilled(Production_Stage) And Not Constants.ProductionStagesAreUsed.Get() Then
		SetPrivilegedMode(True);
		Constants.ProductionStagesAreUsed.Set(True);
		SetPrivilegedMode(False);
	EndIf;
EndProcedure

#EndRegion

#Region Private

Procedure CheckFillingInSpecifiedDetails(VerificationDetails_, AttributesValues, ParametersOfTablePart, DataKey, DataPath, ReportStageName_, Cancel)

	For Each AttributeParameters In VerificationDetails_ Do
		FieldName = AttributeParameters.Value;
		If Not ValueIsFilled(AttributesValues[FieldName]) Then
			
			If ParametersOfTablePart = Undefined Then
				
				Field = FieldName;
				If ReportStageName_
					And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Trường ""%1"" chưa điền (công đoạn:%2).';
								|ru = 'Поле ""%1"" не заполнено (этап: %2).';
								|en = '""%1"" is required (stage: %2).'; fa = '""%1"" is required (stage: %2).';
								|it = 'Campo ""%1"" non compilato (fase: %2).';
								|pl = 'Nie wypełniono pola ""%1"" (etap: %2).';
								|tr = '""%1"" alanı doldurulmadı (aşama: %2).'"), 
							AttributeParameters.Presentation,
							DataKey.Description);
				Else
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Trường ""%1"" chưa điền.';
								|ru = 'Поле ""%1"" не заполнено.';
								|en = '""%1"" is required.'; fa = '""%1"" is required.';
								|it = 'Il campo ""%1"" non è compilato.';
								|pl = 'Nie wypełniono pola ""%1"".';
								|tr = '""%1"" alanı doldurulmadı.'"), 
							AttributeParameters.Presentation);
				EndIf; 
				
			Else

				Field = CommonClientServer.PathToTabularSection(ParametersOfTablePart.Name, ParametersOfTablePart.LineNumber, FieldName);
				If ReportStageName_
					And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Cột ""%1"" trong hàng %2 của danh sách ""%3"" không được điền (bước:%4)';
								|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3"" (этап: %4)';
								|en = 'Column ""%1"" in line %2 of list ""%3"" is required (stage: %4)'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required (stage: %4)';
								|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" (fase: %4) non è compilata';
								|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3"" (etap: %4)';
								|tr = '""%3"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı (aşama: %4)'"), 
							AttributeParameters.Presentation,
							ParametersOfTablePart.LineNumber,
							ParametersOfTablePart.Presentation,
							DataKey.Description);
				Else
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 của danh sách ""%3""';
								|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
								|en = 'Column ""%1"" in line %2 of list ""%3"" is required'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required';
								|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
								|tr = '""%3"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı'"), 
							AttributeParameters.Presentation,
							ParametersOfTablePart.LineNumber,
							ParametersOfTablePart.Presentation);
				EndIf; 
			EndIf; 
					
			Common.MessageToUser(MessageText, DataKey, Field, DataPath, Cancel); 
		EndIf;
	EndDo;

EndProcedure

Procedure FillInNewObject()

	StageNumber = Catalogs.ProductionStages.NewStageNumber(Owner);
	NextStageNo = StageNumber + 1;
	
	If ProductionByThirdParty Then
		Partner = Catalogs.Partners.EmptyRef();
	Else
		Partner = Catalogs.Companies.EmptyRef();
	EndIf;
	
EndProcedure

Function ItIsNecessaryToCalculateDurationOfProduction()
	
	If Not AdditionalProperties.Property("ProhibitCalculationOfDaysBeforeEnd")
		And ValueIsFilled(Ref)
		And ValueIsFilled(Owner)
		And Common.ObjectAttributeValue(Owner, "Status") = Enums.BOMStatuses.Valid Then
		
		DataBeforeChange = Common.ObjectAttributesValues(
			Ref, 
			"Department,StageDuration,UnitOfMeasureOfStageDuration");
		
			If (Department <> DataBeforeChange.Department
					Or StageDuration <> DataBeforeChange.StageDuration
					Or UnitOfMeasureOfStageDuration <> DataBeforeChange.UnitOfMeasureOfStageDuration
				) Then
			
			Return True;
			
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure CheckHeaderDetails(DataKey, ReportStageName_, HasErrors, DataPath)

	ProductionSettings = ProductionServerCached.SubsystemSettingsProduction();
	
	VerificationDetails_ = New ValueList;
	VerificationDetails_.Add("Department", NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Business unit';
												|tr = 'Departman'"));
	
	If PlanOperationsOfWorkCenterTypes Then
		If WorkCenterTypes.Count() > 1 
			And ProductionSettings.ProductionIsUsed22 And Not ProductionSettings.DynamicStructureOfProductionOrders Then
		
			VerificationDetails_.Add(
				"OperatingProcedureOfWorkCenterTypes", 
				NStr("vi = 'Trình tự kết nhập các dạng nguồn lực sản xuất';
					|ru = 'Порядок загрузки видов рабочих центров';
					|en = 'Load procedure of work center types'; fa = 'Load procedure of work center types';
					|it = 'Ordine di carico dei tipi dei centri di lavoro';
					|pl = 'Sposób pobierania rodzajów centrów pracy';
					|tr = 'İş merkezi türlerinin çalışma yükü düzeni'"));
					
		EndIf;
	EndIf;
	
	If ValueIsFilled(StageDuration) Then
		
		VerificationDetails_.Add(
			"UnitOfMeasureOfStageDuration",
			NStr("vi = 'Đơn vị tính thời gian công đoạn';
				|ru = 'Единица измерения длительности этапа';
				|en = 'Stage duration unit of measure'; fa = 'واحد اندازه‌گیری مدت مرحله';
				|it = 'Unità di misura durata della fase';
				|pl = 'Jednostka miary czas trwania etapu';
				|tr = 'Aşama süresi ölçü birimi'"));
		
	EndIf;
	
	If ProductionSettings.ProductionIsUsed22 And Not ProductionSettings.ProductionIsUsed21
		And Not GetFunctionalOption("StoreOperationsInBillsOfMaterials")
		And ValueIsFilled(RouteSheet) Then
		
		VerificationDetails_.Add(
			"RouteSheetFactor",
			NStr("vi = 'Hệ số sơ đồ quy trình';
				|ru = 'Коэффициент маршрутной карты';
				|en = 'Route sheet factor'; fa = 'ضریب برگه مسیر';
				|it = 'Coefficiente della scheda di lavorazione';
				|pl = 'Współczynnik karty technologicznej';
				|tr = 'Rota katsayısı'"));
			
	EndIf;
	
	CheckFillingInSpecifiedDetails(
		VerificationDetails_, ThisObject, Undefined, DataKey, DataPath, ReportStageName_, HasErrors);
	
EndProcedure

Procedure CheckStatusOfOwner(Cancel)
	
	If Cancel Or Not IsNew() Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DoNotCheckStatusOfOwner") Then
		Return;
	EndIf;
	
	OwnerStatus = Common.ObjectAttributeValue(Owner, "Status");
	If OwnerStatus = Enums.BOMStatuses.Valid Then
		Common.MessageToUser(
			NStr("vi = 'Bảng kê chi tiết có trạng thái ""Có hiệu lực"". Không thể thêm các công đoạn mới.';
				|ru = 'Спецификация имеет статус ""Действует"". Добавление новых этапов недоступно.';
				|en = 'The bill of materials has the Valid status. You cannot add new stages.'; fa = 'The bill of materials has the Valid status. You cannot add new stages.';
				|it = 'Спецификация имеет статус ""Действует"". Добавление новых этапов недоступно.';
				|pl = 'The bill of materials has the Valid status. You cannot add new stages.';
				|tr = 'Ürün reçetesi, ""Aktif"" durumuna sahiptir. Yeni işlemler eklenemez.'"),
			Owner,,,
			Cancel);
	EndIf;
	
EndProcedure

Procedure CheckFillingOfTypesOfWorkCenters(DataKey, ReportStageName_, Cancel)
	
	CheckNumberOfTypesOfWorkCenters(DataKey, ReportStageName_, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	DetailsOfTypesOfRC = DetailsOfTypesOfWorkCenters();
	
	ThereIsSynchronousLoad = False;
	For Each KeyAndValue In DetailsOfTypesOfRC Do
		If KeyAndValue.Value.SynchronousLoad Then
			ThereIsSynchronousLoad = True;
			Break;
		EndIf;
	EndDo;
	
	LineNumber = 0;
	NumberOfLinesAdjustmentOptionsAreUsed = 0;
	
	For Each RowMainViewOfRC In WorkCenterTypes Do
		
		LineNumber = LineNumber + 1;
		
		DetailsOfRCType = DetailsOfTypesOfRC.Get(RowMainViewOfRC.WorkCenterType);
		CheckWorkCenterViewLine(
			RowMainViewOfRC, DetailsOfRCType, LineNumber, DataKey, ReportStageName_, ThereIsSynchronousLoad, Cancel);
			
		NumberOfLinesAdjustmentOptionsAreUsed = NumberOfLinesAdjustmentOptionsAreUsed + ?(DetailsOfRCType.SetupSettingsAreUsed, 1, 0);
		
		TheStructureOfTheSearch = New Structure("LinkKeyWorkCenterTypes", RowMainViewOfRC.ConnectionKey);
		AlternativeTypesOfRC = AlternateWorkCenterTypes.FindRows(TheStructureOfTheSearch);
		For Each StringAlternativeViewOfRC In AlternativeTypesOfRC Do
			
			LineNumber = LineNumber + 1;
			
			DetailsOfRCType = DetailsOfTypesOfRC.Get(StringAlternativeViewOfRC.WorkCenterType);
			CheckWorkCenterViewLine(
				StringAlternativeViewOfRC, DetailsOfRCType, LineNumber, DataKey, ReportStageName_, ThereIsSynchronousLoad, Cancel);
				
			NumberOfLinesAdjustmentOptionsAreUsed = NumberOfLinesAdjustmentOptionsAreUsed + ?(DetailsOfRCType.SetupSettingsAreUsed, 1, 0);
			
		EndDo;
		
	EndDo;
	
	If GetFunctionalOption("DynamicStructureOfProductionOrders")
		And NumberOfLinesAdjustmentOptionsAreUsed > 1 Then
		MessageText = NStr("vi = 'Khi bật sử dụng cấu trúc động của đơn hàng sản xuất, đã cấm xác định nhiều hơn một nguồn lực sản xuất mà sử dụng tùy chọn thiết lập';
							|ru = 'При включенной динамической структуре заказов на производство, запрещено задавать более одного ВРЦ, использующего варианты наладки.';
							|en = 'When the dynamic production order structure is enabled, you cannot specify more than one work center type using setup settings.'; fa = 'When the dynamic production order structure is enabled, you cannot specify more than one work center type using setup settings.';
							|it = 'При включенной динамической структуре заказов на производство, запрещено задавать более одного ВРЦ, использующего варианты наладки.';
							|pl = 'When the dynamic production order structure is enabled, you cannot specify more than one work center type using setup settings.';
							|tr = 'Dinamik üretim emri yapısı etkinleştirildiğinde, kurulum seçenekleri kullanılarak birden fazla Çalışma Merkezi Türleri ayarlamak yasaktır.'");
		Common.MessageToUser(MessageText, DataKey, "WorkCenterTypes",, Cancel);
	EndIf;
	
	If ProductionServer.ProductionIsUsed22()
		And OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously
		And Not Cancel Then
		CheckSimultaneousOperationParameters(DetailsOfTypesOfRC, ThereIsSynchronousLoad, DataKey, ReportStageName_, Cancel);
	EndIf;
	
EndProcedure

Procedure CheckNumberOfTypesOfWorkCenters(DataKey, ReportStageName_, Cancel)
	
	If WorkCenterTypes.Count() = 0 Then
		If ReportStageName_
			And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Chưa nhập dòng nào vào danh sách ""Các dạng nguồn lực sản xuất"" (công đoạn: %1).';
										|ru = 'Не введено ни одной строки в список ""Виды рабочих центров"" (этап: %1).';
										|en = 'No lines are entered into the list ""Work center types"" (stage: %1).'; fa = 'No lines are entered into the list ""Work center types"" (stage: %1).';
										|it = 'Non è stata inserita nemmeno una riga nell''elenco ""Tipi di centri di lavoro"" (fase: %1).';
										|pl = 'Nie wprowadzono ani jednego wiersza do listy ""Rodzaje centrów wykonania pracy"" (etap: %1).';
										|tr = '""İş Merkezi Türleri"" listesine herhangi bir satır girilmedi (aşama: %1).'"),
									DataKey.Description);
		Else
			MessageText = NStr("vi = 'Chưa nhập dòng nào vào danh sách ""Các dạng nguồn lực sản xuất"".';
								|ru = 'Не введено ни одной строки в список ""Виды рабочих центров"".';
								|en = 'No lines are entered into the ""Work center types"" list.'; fa = 'No lines are entered into the ""Work center types"" list.';
								|it = 'Non è stata inserita nemmeno una riga nell''elenco ""Tipi di centri di lavoro"".';
								|pl = 'Nie wprowadzono ani jednego wiersza do listy ""Rodzaje centrów wykonania pracy"".';
								|tr = '""İş Merkezi Türleri"" listesine herhangi bir satır girilmedi.'");
		EndIf; 
		Common.MessageToUser(MessageText, DataKey, "WorkCenterTypes",, Cancel);
		Return;
	EndIf;
	
EndProcedure

Procedure CheckWorkCenterViewLine(RowViewRC, DetailsOfRCType, LineNumber, DataKey, ReportStageName_, ThereIsSynchronousLoad, Cancel)

	VerificationDetails_ = New ValueList;
	VerificationDetails_.Add("WorkCenterType", NStr("vi = 'Dạng nguồn lực sản xuất';
													|ru = 'Вид рабочего центра';
													|en = 'Work center type'; fa = 'نوع مرکز کاری';
													|it = 'Tipo di centro di lavoro';
													|pl = 'Rodzaj centrum wykonania pracy';
													|tr = 'İş merkezi türü'"));
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" trong dòng %2 của danh sách ""%3"".';
							|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3"".';
							|en = 'Column ""%1"" in line %2 of list ""%3"" is required.'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required.';
							|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata.';
							|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3"".';
							|tr = '""%3"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı.'");
	MessageTemplateStage = NStr("vi = 'Cột ""%1"" trong hàng %2 của danh sách ""%3"" không được điền (bước:%4).';
								|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3"" (этап: %4).';
								|en = 'Column ""%1"" in line %2 of list ""%3"" is required (stage: %4).'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required (stage: %4).';
								|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" (fase: %4) non è compilata.';
								|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3"" (etap: %4).';
								|tr = '""%3"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı (aşama: %4).'");
	
	ParametersOfTablePart = New Structure("Name,Presentation", "WorkCenterTypes", NStr("vi = 'Dạng nguồn lực sản xuất';
																						|ru = 'Виды рабочих центров';
																						|en = 'Work center types'; fa = 'انواع مرکز کاری';
																						|it = 'Tipi di centri operativi';
																						|pl = 'Rodzaje centrów wykonania pracy';
																						|tr = 'İş merkezi türleri'"));
	ParametersOfTablePart.Insert("LineNumber", LineNumber);
	
	CheckFillingInSpecifiedDetails(VerificationDetails_, RowViewRC, ParametersOfTablePart, DataKey, "", ReportStageName_, Cancel);
	
	// Checking the details, the filling of which depends on the parameters of the type of RC
	If DetailsOfRCType <> Undefined Then
		
		// Checking the completion of the setup option
		If (DetailsOfRCType.SetupSettingsAreUsed = True)
			And Not ValueIsFilled(RowViewRC.SetupSettings) Then
			
			Field = CommonClientServer.PathToTabularSection(ParametersOfTablePart.Name, LineNumber, "SetupSettings");
			If ReportStageName_
				And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplateStage, 
												NStr("vi = 'Phương án thiết lập';
													|ru = 'Вариант наладки';
													|en = 'Setup settings'; fa = 'تنظیمات راه‌اندازی';
													|it = 'Opzione di configurazione';
													|pl = 'Wariant ustawienia';
													|tr = 'Ekipman kurulum ayarları'"),
												LineNumber, 
												ParametersOfTablePart.Presentation,
												DataKey.Description);
			Else
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplate, 
												NStr("vi = 'Phương án thiết lập';
													|ru = 'Вариант наладки';
													|en = 'Setup settings'; fa = 'تنظیمات راه‌اندازی';
													|it = 'Opzione di configurazione';
													|pl = 'Wariant ustawienia';
													|tr = 'Ekipman kurulum ayarları'"),
												LineNumber, 
												ParametersOfTablePart.Presentation);
			EndIf; 
			
			Common.MessageToUser(MessageText, DataKey, Field,, Cancel); 
			
		EndIf;
		
		TimeIsDeterminedByAnotherKindOfRC = Not DetailsOfRCType.SynchronousLoad
			And ThereIsSynchronousLoad
			And OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously
			And ProductionServer.ProductionIsUsed22();
		
		// Checking the working hours
		// With synchronous loading, the time is taken from the RC view and it does not need to be checked.
		If Not ValueIsFilled(RowViewRC.OperationTime)
			And IsBlankString(RowViewRC.QuantityCalculationAlgorithm)
			And Not DetailsOfRCType.SynchronousLoad
			And Not TimeIsDeterminedByAnotherKindOfRC Then
			
			Field = CommonClientServer.PathToTabularSection(ParametersOfTablePart.Name, LineNumber, "OperationTime");
			If ReportStageName_
				And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplateStage, 
												NStr("vi = 'Thời gian làm việc';
													|ru = 'Время работы';
													|en = 'Working time'; fa = 'زمان کاری';
													|it = 'Tempo di lavoro';
													|pl = 'Czas pracy';
													|tr = 'Çalışma süresi'"),
												LineNumber, 
												ParametersOfTablePart.Presentation,
												DataKey.Description);
			Else
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplate, 
												NStr("vi = 'Thời gian làm việc';
													|ru = 'Время работы';
													|en = 'Working time'; fa = 'زمان کاری';
													|it = 'Tempo di lavoro';
													|pl = 'Czas pracy';
													|tr = 'Çalışma süresi'"),
												LineNumber, 
												ParametersOfTablePart.Presentation);
			EndIf;
			
			Common.MessageToUser(MessageText, DataKey, Field,, Cancel); 
		EndIf; 
		
		// Checking The unit of measurement of time
		If Not ValueIsFilled(RowViewRC.UnitOfMeasure)
			And Not DetailsOfRCType.SynchronousLoad
			And Not TimeIsDeterminedByAnotherKindOfRC Then
			
			Field = CommonClientServer.PathToTabularSection(ParametersOfTablePart.Name, LineNumber, "UnitOfMeasure");
			If ReportStageName_
				And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplateStage, 
												NStr("vi = 'Đơn vị tính thời gian';
													|ru = 'Единица измерения времени';
													|en = 'Time unit of measure'; fa = 'واحد اندازه‌گیری زمان';
													|it = 'Unità di misura del tempo';
													|pl = 'Jednostka miary czasu';
													|tr = 'Zaman ölçü birimi'"),
												LineNumber, 
												ParametersOfTablePart.Presentation,
												DataKey.Description);
			Else
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplate, 
												NStr("vi = 'Đơn vị tính thời gian';
													|ru = 'Единица измерения времени';
													|en = 'Time unit of measure'; fa = 'واحد اندازه‌گیری زمان';
													|it = 'Unità di misura del tempo';
													|pl = 'Jednostka miary czasu';
													|tr = 'Zaman ölçü birimi'"),
												LineNumber, 
												ParametersOfTablePart.Presentation);
			EndIf; 
				
			Common.MessageToUser(MessageText, DataKey, Field,, Cancel); 
		EndIf; 
		
		// Checking the download
		If Not ValueIsFilled(RowViewRC.Load)
			And DetailsOfRCType.ParallelLoad Then
			
			Field = CommonClientServer.PathToTabularSection(ParametersOfTablePart.Name, LineNumber, "Load");
			If ReportStageName_
				And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplateStage, 
												NStr("vi = 'Kết nhập';
													|ru = 'Загрузка';
													|en = 'Load'; fa = 'بارگذاری';
													|it = 'Scaricamento';
													|pl = 'Pobieranie';
													|tr = 'Çalışma yükü'"),
												LineNumber, 
												ParametersOfTablePart.Presentation,
												DataKey.Description);
			Else
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplate, 
												NStr("vi = 'Kết nhập';
													|ru = 'Загрузка';
													|en = 'Load'; fa = 'بارگذاری';
													|it = 'Scaricamento';
													|pl = 'Pobieranie';
													|tr = 'Çalışma yükü'"),
												LineNumber, 
												ParametersOfTablePart.Presentation);
			EndIf; 
				
			Common.MessageToUser(MessageText, DataKey, Field,, Cancel); 
		EndIf; 
	
	EndIf; 
	
EndProcedure

Procedure CheckIfStageDurationIsFilledIn(DataKey, ReportStageName_, Cancel)
	
	Settings = ProductionServer.SubsystemSettingsProduction();
	
	CheckIVRCDuration = PlanOperationsOfWorkCenterTypes
		And Settings.PlanningByMaterialResourcesIsUsed
		And Not Settings.PlanningByProductionResourcesIsUsed;
	
	If Not CheckIVRCDuration Then
		Return;
	EndIf;
	
	DurationOfVRC = 0;
	
	For Each String In WorkCenterTypes Do
		
		DurationOfVRC = Max(
			DurationOfVRC,
			ProductionPlanningClientServer.GetTimeInSeconds(String.OperationTime, String.UnitOfMeasure));
		
	EndDo;
	
	StageDurationInSeconds = ProductionPlanningClientServer.GetTimeInSeconds(
		StageDuration,
		UnitOfMeasureOfStageDuration);
	
	If StageDurationInSeconds < DurationOfVRC Then
		
			If ReportStageName_
				And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thời lượng của công đoạn phải lớn hơn hoặc bằng thời gian làm việc của các dạng nguồn lực sản xuất (công đoạn:%1).';
					|ru = 'Длительность этапа должна быть больше или равна времени работы видов рабочих центров (этап: %1).';
					|en = 'Stage duration must be greater or equal to working hours of work center types (stage: %1).'; fa = 'Stage duration must be greater or equal to working hours of work center types (stage: %1).';
					|it = 'La durata della fase deve essere maggiore o uguale alle ore di lavoro dei tipi di centri di lavoro (fase: %1).';
					|pl = 'Czas trwania etapu musi być dłuższy bądź równy czasowi pracy rodzajów centrów pracy (etap: %1).';
					|tr = 'Aşama süresi, iş merkezi türlerinin çalışma süresinden fazla veya bu süreye eşit olmalıdır (aşama: %1).'"),
				DataKey.Description);
			
		Else
				
			MessageText = NStr("vi = 'Thời lượng của công đoạn phải lớn hơn hoặc bằng thời gian làm việc của các dạng nguồn lực sản xuất"".';
								|ru = 'Длительность этапа должна быть больше или равна времени работы видов рабочих центров"".';
								|en = 'Stage duration must be greater or equal to working hours of work center types.'; fa = 'Stage duration must be greater or equal to working hours of work center types.';
								|it = 'La durata della fase deve essere maggiore o uguale alle ore di lavoro dei tipi di centri di lavoro"".';
								|pl = 'Czas trwania etapu musi być dłuższy bądź równy czasowi pracy rodzajów centrów pracy"".';
								|tr = 'Aşama süresi, iş merkezi türlerinin çalışma süresinden fazla veya bu süreye eşit olmalıdır"".'");
			
		EndIf;
		
		Common.MessageToUser(MessageText, DataKey, "StageDuration",, Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckSimultaneousOperationParameters(DetailsOfTypesOfRC, ThereIsSynchronousLoad, DataKey, ReportStageName_, Cancel)
	
	WorkingTimeIsSame = True;
	
	ValidationValues = Undefined;
		
	For Each KeyAndValue In DetailsOfTypesOfRC Do
		
		If Not ThereIsSynchronousLoad
			Or KeyAndValue.Value.SynchronousLoad Then
			
			If ValidationValues = Undefined Then
				ValidationValues = KeyAndValue.Value;
			Else
				
				If KeyAndValue.Value.OperationTime <> ValidationValues.OperationTime
					Or KeyAndValue.Value.UnitOfMeasure <> ValidationValues.UnitOfMeasure Then
					
					WorkingTimeIsSame = False;
					Break;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not WorkingTimeIsSame Then
		
		If ReportStageName_
			And DataKey <> Undefined And ValueIsFilled(DataKey.Description) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi sử dụng trình tự kết nhập ""Đồng thời"", thời gian làm việc của các dạng nguồn lực sản xuất phải giống nhau (công đoạn: %1).';
					|ru = 'При использовании порядка загрузки ""Одновременно"" время работы видов рабочих центров должно быть одинаковым (этап: %1).';
					|en = 'When using the ""Simultaneously"" load procedure, working time of work center types must be the same (stage: %1).'; fa = 'When using the ""Simultaneously"" load procedure, working time of work center types must be the same (stage: %1).';
					|it = 'Quando si utilizza la procedura di caricamento ""Simultaneamente"", le ore di lavoro dei tipi di centri di lavoro devono essere le stesse (fase: %1).';
					|pl = 'Podczas korzystania z trybu pobierania ""Jednocześnie"" godziny pracy rodzajów centrów pracy muszą być takie same (etap: %1).';
					|tr = '""Eş zamanlı"" yükleme düzeni kullanılırken, iş merkezi türlerinin çalışma süreleri aynı olmalıdır (aşama: %1).'"),
				DataKey.Description);
		Else
			MessageText = NStr("vi = 'Khi sử dụng trình tự kết nhập ""Đồng thời"", thời gian làm việc của các dạng nguồn lực sản xuất phải giống nhau.';
								|ru = 'При использовании порядка загрузки ""Одновременно"" время работы видов рабочих центров должно быть одинаковым.';
								|en = 'When using the ""Simultaneously"" load procedure, working time of work center types must be the same.'; fa = 'When using the ""Simultaneously"" load procedure, working time of work center types must be the same.';
								|it = 'Quando si utilizza la procedura di caricamento ""Simultaneamente"", le ore di lavoro dei tipi di centri di lavoro devono essere le stesse.';
								|pl = 'Podczas korzystania z trybu pobierania ""Jednocześnie"" czas pracy rodzajów centrów roboczych powinny być takie same.';
								|tr = '""Eş zamanlı"" yükleme düzeni kullanılırken, iş merkezi türlerinin çalışma süreleri aynı olmalıdır.'");
		EndIf; 
		
		Common.MessageToUser(MessageText, DataKey, "WorkCenterTypes",, Cancel);
		
	EndIf;
	
EndProcedure

Function DetailsOfTypesOfWorkCenters()
	
	Query = New Query("
	|SELECT
	|	WorkCenterTypes.WorkCenterType AS WorkCenterType,
	|	WorkCenterTypes.SetupSettings    AS SetupSettings,
	|	WorkCenterTypes.OperationTime       AS OperationTime,
	|	WorkCenterTypes.UnitOfMeasure  AS UnitOfMeasure
	|
	|INTO TTTypesOfWorkCenters
	|FROM
	|	&WorkCenterTypes AS WorkCenterTypes
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	AlternateWorkCenterTypes.WorkCenterType AS WorkCenterType,
	|	AlternateWorkCenterTypes.SetupSettings    AS SetupSettings,
	|	AlternateWorkCenterTypes.OperationTime       AS OperationTime,
	|	AlternateWorkCenterTypes.UnitOfMeasure  AS UnitOfMeasure
	|
	|INTO TTAlternativeTypesOfWorkCenters
	|FROM
	|	&AlternateWorkCenterTypes AS AlternateWorkCenterTypes
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	WorkCenterTypes.WorkCenterType,
	|	CASE
	|		WHEN WorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN WorkCenterTypes.OperationTime
	|		WHEN WorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND WorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND NOT WorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN WorkCenterTypes.WorkCenterType.OperationTime
	|		WHEN WorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND WorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND WorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN WorkCenterTypes.SetupSettings.OperationTime
	|		ELSE WorkCenterTypes.OperationTime
	|	END AS OperationTime,
	|	CASE
	|		WHEN WorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN WorkCenterTypes.UnitOfMeasure
	|		WHEN WorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND WorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND NOT WorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN WorkCenterTypes.WorkCenterType.UnitOfMeasure
	|		WHEN WorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND WorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND WorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN WorkCenterTypes.SetupSettings.UnitOfMeasure
	|		ELSE WorkCenterTypes.UnitOfMeasure
	|	END AS UnitOfMeasure,
	|	CASE
	|		WHEN WorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN FALSE
	|		ELSE WorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|	END AS SetupSettingsAreUsed,
	|	CASE
	|		WHEN WorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN FALSE
	|		ELSE WorkCenterTypes.WorkCenterType.ParallelLoad
	|	END AS ParallelLoad,
	|	CASE
	|		WHEN WorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN FALSE
	|		ELSE WorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND WorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|	END AS SynchronousLoad
	|FROM
	|	TTTypesOfWorkCenters AS WorkCenterTypes
	|
	|UNION ALL
	|
	|SELECT
	|	AlternateWorkCenterTypes.WorkCenterType,
	|	CASE
	|		WHEN AlternateWorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN AlternateWorkCenterTypes.OperationTime
	|		WHEN AlternateWorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND AlternateWorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND NOT AlternateWorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN AlternateWorkCenterTypes.WorkCenterType.OperationTime
	|		WHEN AlternateWorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND AlternateWorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND AlternateWorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN AlternateWorkCenterTypes.SetupSettings.OperationTime
	|		ELSE AlternateWorkCenterTypes.OperationTime
	|	END,
	|	CASE
	|		WHEN AlternateWorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN AlternateWorkCenterTypes.UnitOfMeasure
	|		WHEN AlternateWorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND AlternateWorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND NOT AlternateWorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN AlternateWorkCenterTypes.WorkCenterType.UnitOfMeasure
	|		WHEN AlternateWorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND AlternateWorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND AlternateWorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|			THEN AlternateWorkCenterTypes.SetupSettings.UnitOfMeasure
	|		ELSE AlternateWorkCenterTypes.UnitOfMeasure
	|	END,
	|	CASE
	|		WHEN AlternateWorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN FALSE
	|		ELSE AlternateWorkCenterTypes.WorkCenterType.SetupSettingsAreUsed
	|	END,
	|	CASE
	|		WHEN AlternateWorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN FALSE
	|		ELSE AlternateWorkCenterTypes.WorkCenterType.ParallelLoad
	|	END,
	|	CASE
	|		WHEN AlternateWorkCenterTypes.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			THEN FALSE
	|		ELSE AlternateWorkCenterTypes.WorkCenterType.ParallelLoad
	|				AND AlternateWorkCenterTypes.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|	END
	|FROM
	|	TTAlternativeTypesOfWorkCenters AS AlternateWorkCenterTypes
	|");
	
	Query.SetParameter("WorkCenterTypes", WorkCenterTypes);
	Query.SetParameter("AlternateWorkCenterTypes", AlternateWorkCenterTypes);
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	
	Result = New Map;
	
	While Selection.Next() Do
		
		AttributesValues = New Structure;
		AttributesValues.Insert("SetupSettingsAreUsed");
		AttributesValues.Insert("ParallelLoad");
		AttributesValues.Insert("SynchronousLoad");
		AttributesValues.Insert("OperationTime");
		AttributesValues.Insert("UnitOfMeasure");
		
		FillPropertyValues(AttributesValues, Selection);
		
		Result.Insert(Selection.WorkCenterType, AttributesValues);
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure FillInServiceDetailsCached() Export
	
	ContainsResourcesParametrization = SelectionByProperties.Count() > 0;
	
	If Not ContainsResourcesParametrization Then
		For Each TSRow In WorkCenterTypes Do
			If Not IsBlankString(TSRow.QuantityCalculationAlgorithm) Then
				ContainsResourcesParametrization = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not ContainsResourcesParametrization Then
		For Each TSRow In AlternateWorkCenterTypes Do
			If Not IsBlankString(TSRow.QuantityCalculationAlgorithm) Then
				ContainsResourcesParametrization = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf