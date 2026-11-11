#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Item = Items.Add();
	Item.PredefinedDataName = "VAT";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT';
																					|ru = 'НДС';
																					|en = 'VAT';
																					|it = 'НДС';
																					|pl = 'VAT';
																					|tr = 'KDV'", LanguagesCodes);// @NStr-2

	TaxContributionKindsLocalization.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.PackagingGroups - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	Return;
EndProcedure

// Get a link of a predefined element.
// 
// Parameters:
//  PredefinedItemName - String - Name of the predefined element
// 
// Returns:
//  CatalogRef.TaxContributionKinds - Get A Link Of A Predefined Element
Function GetLinkOfPredefinedElement(PredefinedItemName) Export

	CatalogObject = Catalogs.TaxContributionKinds.CreateItem();
	PredefinedItemsNames = CatalogObject.Metadata().GetPredefinedNames();
	HasPredefinedOne = False;
	For Each Item In PredefinedItemsNames Do
		If Lower(Item) = Lower(PredefinedItemName) Then 
			HasPredefinedOne = True;
			Break;
		EndIf;
	EndDo;
	If HasPredefinedOne Then
		Return Catalogs.TaxContributionKinds[PredefinedItemName];
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TaxContributionKinds.Ref AS Ref
	|FROM
	|	Catalog.TaxContributionKinds AS TaxContributionKinds
	|WHERE
	|	LOWER(TaxContributionKinds.ItemID) = &Id";
	Query.SetParameter("Id", Lower(PredefinedItemName));
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Ref = Selection.Ref;
	Else
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.TaxContributionKinds");
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Description =  NameOfPredefinedElement(PredefinedItemName); // String
			//@skip-check bsl-nstr-string-literal-format
			CatalogObject.Description = NStr(Description, Common.DefaultLanguageCode());
			CatalogObject.ItemID = PredefinedItemName;
			CatalogObject.Write();
			Ref = CatalogObject.Ref;
			CommitTransaction();
		Except

			RollbackTransaction();

			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể ghi lại phần tử định trước của danh mục ""Dạng thuế và lệ phí"" %1:
					|%2';
					|ru = 'Не удалось записать предопределенный элемент справочника ""Виды налогов и взносов"" %1:
					|%2';
					|en = 'Cannot save the %1 predefined item of the ""Tax and contribution kinds"" catalog:
					|%2'; fa = 'Cannot save the %1 predefined item of the ""Tax and contribution kinds"" catalog:
					|%2';
					|it = 'Не удалось записать предопределенный элемент справочника ""Виды налогов и взносов"" %1:
					|%2';
					|pl = 'Cannot save the %1 predefined item of the ""Tax and contribution kinds"" catalog:
					|%2';
					|tr = '“Vergi ve katkı payı türleri” dizininin önceden tanımlanmış bir öğesi yazılamadı %1:
					|%2'"),
				PredefinedItemName,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			Raise ExceptionText;
		EndTry;
	EndIf;
	
	Return Ref;
EndFunction

// Name of the predefined element.
// 
// Parameters:
//  PredefinedItemName - String - Name of the predefined element
// 
// Returns:
//  String - naming a predefined element
Function NameOfPredefinedElement(PredefinedItemName) Export
	Description = "";
	If PredefinedItemName = "VAT_ImportedGoods" Then
		Description = "vi = 'Thuế GTGT khi nhập khẩu hàng hóa từ EAEU';
						|ru = 'НДС при импорте товаров из ЕАЭС';
						|en = 'VAT on goods import from EAEU';
						|it = 'НДС при импорте товаров из ЕАЭС';
						|pl = 'VAT od importu towarów z EWG';
						|tr = 'AEB üzerinden ürün ithalatındaki KDV'"; // @NStr-1
	ElsIf PredefinedItemName = "VAT_TaxAgent" Then
		Description = "vi = 'Thuế GTGT khi thực hiện nghĩa vụ của đại lý thuế';
						|ru = 'НДС при исполнении обязанностей налогового агента';
						|en = 'VAT when acting as a tax agent';
						|it = 'НДС при исполнении обязанностей налогового агента';
						|pl = 'VAT podczas wykonania obowiązków agenta podatkowego';
						|tr = 'Vergi memurunun görevlerini yerine getirirken KDV'"; // @NStr-1
	EndIf;
	If IsBlankString(Description) Then
		Description = Enums.DeleteTaxTypes.NameOfPredefinedElement(PredefinedItemName);
	EndIf;
	Return Description;
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	TaxContributionKindsLocalization.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing);
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.TaxContributionKinds);
	// End StandardSubsystems.Core
	
EndProcedure

#EndIf

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array - names of blocked Bank details:
//		* AttributeToLock - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("TaxPayer");
	
	Return Result;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.TaxContributionKinds.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("1b2eda1e-2253-499a-afc3-80d2534fd1a9");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.TaxContributionKinds.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Dạng thuế và lệ phí"":';
								|ru = 'Обновление справочника ""Виды налогов и взносов"":';
								|en = 'Update the ""Tax and contribution kinds"" catalog:'; fa = 'Update the ""Tax and contribution kinds"" catalog:';
								|it = 'Update the ""Tax and contribution kinds"" catalog:';
								|pl = 'Update the ""Tax and contribution kinds"" catalog:';
								|tr = '""Vergi ve katkı payı türleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin danh mục đa ngôn ngữ';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.TaxContributionKinds.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.TaxContributionKinds.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.TaxContributionKinds.FullName());
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
	|	TaxContributionKinds.Ref AS Ref
	|FROM
	|	Catalog.TaxContributionKinds AS TaxContributionKinds
	|WHERE
	|	NOT TaxContributionKinds.Description = """"
	|	AND TaxContributionKinds.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	TaxContributionKinds.Ref AS Ref
	|FROM
	|	Catalog.TaxContributionKinds AS TaxContributionKinds
	|WHERE
	|	NOT TaxContributionKinds.Description = """"
	|	AND TaxContributionKinds.DescriptionLanguage2 = """"";
	
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
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Dạng thuế và lệ phí"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Виды налогов и взносов"" по обработчику:';
								|en = 'Cannot process the ""Tax and contribution kinds"" catalog by the handler:'; fa = 'Cannot process the ""Tax and contribution kinds"" catalog by the handler:';
								|it = 'Cannot process the ""Tax and contribution kinds"" catalog by the handler:';
								|pl = 'Cannot process the ""Tax and contribution kinds"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Vergi ve katkı payı türleri"" kataloğu işlenemedi:'"));
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
	|	TaxContributionKinds.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.TaxContributionKinds AS TaxContributionKinds
	|		ON TT.Ref = TaxContributionKinds.Ref";
	
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
