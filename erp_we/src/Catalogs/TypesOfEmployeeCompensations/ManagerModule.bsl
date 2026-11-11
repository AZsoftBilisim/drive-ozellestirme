#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// Called when you first fill in the reference list of types of calculations by Employees.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of the columns corresponds to the set of details
//                                 of the reference book types of calculations by Employees.
//  TabularSections - Structure - description of the table parts of the object, where:
//   * Key - String - name of the table part;
//   * Value - ValueTable - the tabular part in the form of a table of values, the structure of which
//                                  must be copied before filling in. For example:
//                                  Element.Keys = Table parts.Keys.Copy();
//                                  ELEMENTH = Element.Keys.Add();
//                                  The HATCH element.Keyname = "Primary";
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Item = Items.Add();
	Item.Code = "00-000001";
	Item.PredefinedDataName = "Payroll";
	Item.Description = NStr("vi = 'Trả tiền lương';
							|ru = 'Оплата труда';
							|en = 'Payroll'; fa = 'حقوق و دستمزد';
							|it = 'Retribuzione';
							|pl = 'Wynagrodzenie';
							|tr = 'Aylık maaş'", Common.DefaultLanguageCode());
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.TypesOfEmployeeCompensations);
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.TypesOfEmployeeCompensations.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("0f55ee1c-4cf9-42d4-87ad-8357b7b8d168");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.TypesOfEmployeeCompensations.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Dạng hạch toán với người lao động"":';
								|ru = 'Обновление справочника ""Виды расчетов с сотрудниками"":';
								|en = 'Update the ""Types of employee compensations"" catalog:'; fa = 'Update the ""Types of employee compensations"" catalog:';
								|it = 'Update the ""Types of employee compensations"" catalog:';
								|pl = 'Update the ""Types of employee compensations"" catalog:';
								|tr = '""Çalışanlar ile alacak/borç türleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin danh mục đa ngôn ngữ';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.TypesOfEmployeeCompensations.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.TypesOfEmployeeCompensations.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.TypesOfEmployeeCompensations.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AdditionalLanguagesAreUsed Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TypesOfEmployeeCompensations.Ref AS Ref
	|FROM
	|	Catalog.TypesOfEmployeeCompensations AS TypesOfEmployeeCompensations
	|WHERE
	|	NOT TypesOfEmployeeCompensations.Description = """"
	|	AND TypesOfEmployeeCompensations.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	TypesOfEmployeeCompensations.Ref AS Ref
	|FROM
	|	Catalog.TypesOfEmployeeCompensations AS TypesOfEmployeeCompensations
	|WHERE
	|	NOT TypesOfEmployeeCompensations.Description = """"
	|	AND TypesOfEmployeeCompensations.DescriptionLanguage2 = """"";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Dạng hạch toán với người lao động"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Виды расчетов с сотрудниками"" по обработчику:';
								|en = 'Cannot process the ""Types of employee compensations"" catalog by the handler:'; fa = 'Cannot process the ""Types of employee compensations"" catalog by the handler:';
								|it = 'Cannot process the ""Types of employee compensations"" catalog by the handler:';
								|pl = 'Cannot process the ""Types of employee compensations"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Çalışanlar ile alacak/borç türleri"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	TypesOfEmployeeCompensations.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.TypesOfEmployeeCompensations AS TypesOfEmployeeCompensations
	|		ON TT.Ref = TypesOfEmployeeCompensations.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
					
					CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
					
				EndIf;
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
					
					CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf