
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure changes the codes of the passed element and the nearest element
// in the specified direction.
//
// Parameters:
//  Item  - CatalogRef.BudgetingSteps - The element that we are changing the code for.
//  Direction  - Number - Which way to change the code (+1, -1).
//
Procedure ShiftElement(Item, Direction) Export
	
	Query = New Query(
	"SELECT
	|	BudgetingSteps.Ref,
	|	BudgetingSteps.Parent,
	|	BudgetingSteps.Code + &Offset AS Code,
	|	BudgetingSteps.Owner
	|INTO CurrentItem
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetingSteps.Ref,
	|	CASE
	|		WHEN BudgetingSteps.Ref = CurrentItem.Ref
	|			THEN CurrentItem.Code
	|		ELSE BudgetingSteps.Code
	|	END AS CodeOrder,
	|	CASE
	|		WHEN BudgetingSteps.Ref = CurrentItem.Ref
	|			THEN &Offset
	|		ELSE 0
	|	END AS AdditionalProcedure,
	|	BudgetingSteps.Code
	|FROM
	|	CurrentItem AS CurrentItem
	|		LEFT JOIN Catalog.BudgetingSteps AS BudgetingSteps
	|		ON CurrentItem.Parent = BudgetingSteps.Parent
	|			AND CurrentItem.Owner = BudgetingSteps.Owner
	|
	|ORDER BY
	|	CodeOrder,
	|	AdditionalProcedure");
	
	Query.SetParameter("Ref", Item);
	Query.SetParameter("Offset", Direction);
	
	Selection = Query.Execute().Select();
	Cnt = 0;
	While Selection.Next() Do
		Cnt = Cnt + 1;
		If Cnt <> Selection.Code Then
			Object = Selection.Ref.GetObject();
			Object.Code = Cnt;
			Object.MCodeUpdateMode = True;
			Object.Write();
		EndIf;
	EndDo;
	
EndProcedure

// The procedure renumbers the entire group of elements
// is used when an element is moved to a new group - the old group is renumbered.
//
// Parameters:
//  Parent  - CatalogRef.BudgetingSteps - The group, which should be renumbered.
//  PortableElement  - CatalogRef.BudgetingSteps - The element that we are transferring from the group.
//
Procedure RenumberGroupOfElements(Parent, PortableElement) Export
	
	Query = New Query(
	"SELECT
	|	BudgetingSteps.Ref,
	|	BudgetingSteps.Code
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Parent = &Parent
	|	AND BudgetingSteps.Ref <> &Ref
	|
	|ORDER BY
	|	BudgetingSteps.Code");
	
	Query.SetParameter("Parent", Parent);
	Query.SetParameter("Ref", PortableElement);
	
	Selection = Query.Execute().Select();
	Cnt = 0;
	While Selection.Next() Do
		Cnt = Cnt + 1;
		If Cnt <> Selection.Code Then
			Object = Selection.Ref.GetObject();
			Object.Code = Cnt;
			Object.MCodeUpdateMode = True;
			Object.Write();
		EndIf;
	EndDo;
	
EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Periodicity");
	Result.Add("StageExecutionProcedure");
	
	Return Result;
	
EndFunction

// Brings the types of budget item analytics in the action settings to the metadata of the current configuration
//
Procedure UpdateActionSettings() Export
	
	Selection = Catalogs.BudgetingSteps.Select();
	While Selection.Next() Do
		If Not Selection.IsFolder Then
			
			CatalogObject = Selection.Ref.GetObject();
			SettingOfAction = CatalogObject.SettingOfAction.Get();
			
			If SettingOfAction <> Undefined And TypeOf(SettingOfAction) = Type("ValueTable") Then
				If SettingOfAction.Columns.Find("Name") <> Undefined
					And SettingOfAction.Columns.Find("Value") <> Undefined Then
					
					For Each TableRow1 In SettingOfAction Do
						If TableRow1.Name = "BudgetPopulationDimension" Then
							
							Table = TableRow1.Value;
							TableCopy = Table.CopyColumns();
							
							For Indus = 1 To 6 Do
								AnalyticsColumn = TableCopy.Columns.Find("Dimension" + String(Indus));
								If AnalyticsColumn <> Undefined Then
									TableCopy.Columns.Delete(AnalyticsColumn);
									TableCopy.Columns.Add("Dimension" + String(Indus),
										Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Type);
								EndIf;
							EndDo;
							
							For Each TableRow2 In Table Do
								FillPropertyValues(TableCopy.Add(), TableRow2);
							EndDo;
							
							TableRow1.Value = TableCopy;
						Else
							Continue;
						EndIf;
					EndDo;
					
					CatalogObject.SettingOfAction = New ValueStorage(SettingOfAction);
					CatalogObject.Write();
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.BudgetingSteps.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.3";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a2cd2d9c-ee2f-44b2-a5a4-69db33bc857e");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.BudgetingSteps.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Thêm cột ""Quy tắc tính toán"", ""Tính định kỳ"" vào bảng ""Dạng ngân sách"" mà được lưu trong mục tin ""Tùy chỉnh hiệu lực"".';
							|ru = 'Добавляет колонки ""Правило расчета"", ""Периодичность"" в таблицу ""Виды бюджетов"", хранящуюся в реквизите ""Настройка действия"".';
							|en = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.'; fa = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.';
							|it = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.';
							|pl = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.';
							|tr = '""Eylem ayarları"" özniteliğinde saklı ""Bütçe profilleri"" tablosuna ""Hesaplama kuralı"" ve ""Sıklık"" sütunlarını ekler.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.BudgetingSteps.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.BudgetingSteps.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.BudgetingSteps.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// LongDesc
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters = Undefined) Export
	
	MetadataObjectName = Metadata.Catalogs.BudgetingSteps.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = MetadataObjectName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT
	|	BudgetingSteps.Ref AS Ref,
	|	BudgetingSteps.SettingOfAction AS SettingOfAction
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Action IN (VALUE(Enum.TypesOfBudgetingStepActions.FillingBudgetEntryForm), VALUE(Enum.TypesOfBudgetingStepActions.AdjustCorrectBudgets))";
	
	Query = New Query(QueryText);
	Result = Query.Execute();
	
	ResultTable1 = Result.Unload();
	DataProcessorRefs = New Array;
	For Each TableRow In ResultTable1 Do
		SettingOfAction = TableRow.SettingOfAction.Get();
		If TypeOf(SettingOfAction) = Type("ValueTable") Then
			LineTypesOfBudgets = SettingOfAction.Find("BudgetProfiles", "Name");
			If LineTypesOfBudgets = Undefined Then
				Continue;
			EndIf;
			TableTypesOfBudgets = LineTypesOfBudgets.Value; // -ValueTable-
			If TableTypesOfBudgets.Columns.Find("CalculationRule") = Undefined
				Or TableTypesOfBudgets.Columns.Find("Periodicity") = Undefined Then
				DataProcessorRefs.Add(TableRow.Ref);
			EndIf;
		EndIf;
	EndDo;
	
	InfobaseUpdate.MarkForProcessing(Parameters, DataProcessorRefs);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	MetadataObject = Metadata.Catalogs.BudgetingSteps;
	MetadataObjectName = MetadataObject.FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, MetadataObjectName);
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Giai đoạn chuẩn bị ngân sách"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Этапы подготовки бюджетов"" по обработчику:';
								|en = 'Cannot process the ""Budgeting steps"" catalog by the handler:'; fa = 'Cannot process the ""Budgeting steps"" catalog by the handler:';
								|it = 'Cannot process the ""Budgeting steps"" catalog by the handler:';
								|pl = 'Cannot process the ""Budgeting steps"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Bütçe hazırlık aşamaları"" katalogu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- khi xử lý bảng ""Dạng ngân sách"" trong mục tin ""Tùy chỉnh hiệu lực""';
								|ru = '- при обработке таблицы ""Виды бюджетов"" в реквизите ""Настройка действия""';
								|en = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute'; fa = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute';
								|it = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute';
								|pl = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute';
								|tr = '- ""Eylem ayarı"" özniteliğindeki ""Bütçe profilleri"" tablosunun işlenmesi sırasında'"));

	For Each Selection In UpdatedData Do
	
		ExceptionReason = "";
		Recommendation = "";

		BeginTransaction();

		Try
			
			Stage = Selection.Ref; // CatalogRef.BudgetingSteps - 
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			LockItem = Block.Add(MetadataObjectName);
			LockItem.SetValue("Ref", Stage);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kiểm tra dữ liệu thủ công.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");

			StageObject = Stage.GetObject();
			SettingOfAction = StageObject.SettingOfAction.Get();
			LineTypesOfBudgets = SettingOfAction.Find("BudgetProfiles", "Name");
			If LineTypesOfBudgets = Undefined Then
				CommitTransaction();
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
				Continue;
			EndIf;
			TableTypesOfBudgets = LineTypesOfBudgets.Value; // - ValueTable -
			YouNeedToOverwriteObject = False;
			If TableTypesOfBudgets.Columns.Find("CalculationRule") = Undefined Then
				TableTypesOfBudgets.Columns.Add("CalculationRule",
					New TypeDescription("CatalogRef.RuleForCalculatingRelatedBudgetBalancesAndTurnovers"));
				YouNeedToOverwriteObject = True;
			EndIf;
			If TableTypesOfBudgets.Columns.Find("Periodicity") = Undefined Then
				TableTypesOfBudgets.Columns.Add("Periodicity",
					New TypeDescription("EnumRef.Periodicity"));
				YouNeedToOverwriteObject = True;
			EndIf;
			
			ExceptionReason = "Record";

			If YouNeedToOverwriteObject Then
				StageObject.SettingOfAction = New ValueStorage(SettingOfAction);
				InfobaseUpdate.WriteObject(StageObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(Selection.Ref, Recommendation,
					ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed,
					Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		MetadataObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf