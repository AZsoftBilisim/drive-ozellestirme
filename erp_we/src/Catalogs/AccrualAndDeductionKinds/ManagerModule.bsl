#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.AccrualAndDeductionKinds);
	
EndProcedure

#EndRegion

#Region Internal

//++ WE
Procedure SetUpRegistrationForm(Form) Export
	
	Object = Form.Object;
	
	FilterTable = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.NewFilterTable();
	
	ReflectionParameters	= SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillReflectionParameters(Object.Ref);
	
	NewRow = FilterTable.Add();
	NewRow.TypeOfAccrualDeduction = Object.Ref; 
	ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(FilterTable, CurrentSessionDate());
		
	// Filling in the header
	DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
	DetailsOfFillingInForm.FilterTable = FilterTable;
	DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
	DetailsOfFillingInForm.FilterDate = CurrentSessionDate();
	DetailsOfFillingInForm.RecordingSettingPresentation = "RecordingSettingPresentation";
	DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionSettingIsCorrect";
		
     SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedHeaderDetails(Form, ReflectionParameters, DetailsOfFillingInForm);
	  
EndProcedure 

Function ToControlFillingOfReflectionInAccounting(Form) Export

	ControlLevels = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels();
	Object = Form.Object;
	
	ControlParameters = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetControlParameters();
	ControlParameters.TypeOfAccrualDeduction = Object.Ref; 
	ControlParameters.DateOfControl = CurrentSessionDate(); 
	ControlParameters.ControlLevel = ControlLevels.AccrualRetentionLevel;
	
	Return SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.CheckCompletionOfReflectionInAccounting(ControlParameters);	
	
EndFunction

Function OptionsForReflectingAccruals() Export
	
	ReflectionOptions = New Map;
	
	// Reflection of costs by item of expenditure
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses,
		NStr("vi = 'Số tiền được đưa vào tài khoản dưới dạng chi phí được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма принимается к учету как постатейный расход и распределяется в соответствии с настройками статьи';
			|en = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings'; fa = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings';
			|it = 'L''importo viene registrato in contabilità come spesa dettagliata per articolo e ripartita secondo le impostazioni della voce di spesa';
			|pl = 'Wartość jest przyjmowana do ewidencji jako rozchód wg pozycji i dzielony zgodnie z ustawieniami pozycji';
			|tr = 'Tutar, kalemler bazında gider olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"ExpenseItem, DimensionOfExpenses, LineOfBusiness");
	OptionDetails.CheckFilling = False;
	
	ExpenseItem = OptionDetails.AttributeProperties.ExpenseItem; // See PropertiesOfReflectionProps
	ExpenseItem.Main = True;
	
	LineOfBusiness = OptionDetails.AttributeProperties.LineOfBusiness; // See PropertiesOfReflectionProps
	LineOfBusiness.Used = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	LineOfBusiness.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Reflection of costs under the item of assets/liabilities
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities,
		NStr("vi = 'Số tiền được đưa vào tài khoản dưới dạng chi phí được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма принимается к учету как постатейный расход и распределяется в соответствии с настройками статьи';
			|en = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings'; fa = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings';
			|it = 'L''importo viene registrato in contabilità come spesa dettagliata per articolo e ripartita secondo le impostazioni della voce di spesa';
			|pl = 'Wartość jest przyjmowana do ewidencji jako rozchód wg pozycji i dzielony zgodnie z ustawieniami pozycji';
			|tr = 'Tutar, kalemler bazında gider olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"ExpenseAssetLiabilityItem, AssetsLiabilitiesDimension, ExpenseLedgerAccountsSettings, LineOfBusiness");
	OptionDetails.CheckFilling = False;
	
	OptionDetails.Used = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	
	ExpenseItem = OptionDetails.AttributeProperties.ExpenseAssetLiabilityItem; // See PropertiesOfReflectionProps
	ExpenseItem.Main = True;
	
	GLAccountSettings = OptionDetails.AttributeProperties.ExpenseLedgerAccountsSettings; // See PropertiesOfReflectionProps
	GLAccountSettings.Used =
		GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured() Or GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
	LineOfBusiness = OptionDetails.AttributeProperties.LineOfBusiness; // See PropertiesOfReflectionProps
	LineOfBusiness.Used = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	LineOfBusiness.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Distribution of production costs
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.AllocateToProduction,
		NStr("vi = 'Số tiền đã trích được phân bổ vào các lô sản xuất theo sản lượng của nhân viên';
			|ru = 'Начисленная сумма распределяется на партии производства по выработке сотрудников';
			|en = 'Accrued amount is allocated to production lots for timesheets charge'; fa = 'Accrued amount is allocated to production lots for timesheets charge';
			|it = 'L''importo maturato viene ripartito per lotti di produzione in base alla produttività dei dipendenti';
			|pl = 'Naliczona kwota przydziela się na partie produkcji wg wydajności pracowników';
			|tr = 'Tahakkuk eden tutar, zaman çizelgesi bazlı ücretlendirmeye dayalı olarak üretim lotlarına dağıtılır'"),
		"AllocationBaseType, ProductCostElement");
	
	AllocationBaseType = OptionDetails.AttributeProperties.AllocationBaseType; // See PropertiesOfReflectionProps
	AllocationBaseType.Main = True;
	
	ProductCostElement = OptionDetails.AttributeProperties.ProductCostElement; // See PropertiesOfReflectionProps
	ProductCostElement.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// 
	
	Return New FixedMap(ReflectionOptions);
	
EndFunction

Function OptionsForReflectingDeductions() Export
	
	ReflectionOptions = New Map;
	
	// Reflection of deductions by income item
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome,
		NStr("vi = 'Số tiền khấu trừ được tính đến dưới dạng thu nhập được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма удержания принимается к учету как постатейный доход и распределяется в соответствии с настройками статьи';
			|en = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.'; fa = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.';
			|it = 'L''importo della trattenuta viene registrato come entrata dettagliata per articolo e ripartita secondo le impostazioni della voce';
			|pl = 'Wartość potrącenia jest przyjmowana do ewidencji dochód wg pozycji i przydziela się zgodnie z ustawieniami pozycji';
			|tr = 'Stopaj tutarı kalem bazlı gelir olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"IncomeItem, DimensionOfRevenue");
	OptionDetails.CheckFilling = False;
	
	IncomeItem = OptionDetails.AttributeProperties.IncomeItem; // See PropertiesOfReflectionProps
	IncomeItem.Main = True;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Reflection of deductions under the item of assets/liabilities
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities,
		NStr("vi = 'Số tiền khấu trừ được tính đến dưới dạng thu nhập được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма удержания принимается к учету как постатейный доход и распределяется в соответствии с настройками статьи';
			|en = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.'; fa = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.';
			|it = 'L''importo della trattenuta viene registrato come entrata dettagliata per articolo e ripartita secondo le impostazioni della voce';
			|pl = 'Wartość potrącenia jest przyjmowana do ewidencji dochód wg pozycji i przydziela się zgodnie z ustawieniami pozycji';
			|tr = 'Stopaj tutarı kalem bazlı gelir olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"IncomeAssetLiabilityItem, AnalyticsOfAssetsIncomeLiabilities, IncomeLedgerAccountsSettings");
	OptionDetails.CheckFilling = False;
	
	OptionDetails.Used = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	
	IncomeItem = OptionDetails.AttributeProperties.IncomeAssetLiabilityItem; // See PropertiesOfReflectionProps
	IncomeItem.Main = True;
	
	GLAccountSettings = OptionDetails.AttributeProperties.IncomeLedgerAccountsSettings; // See PropertiesOfReflectionProps
	GLAccountSettings.Used =
		GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured() Or GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Repayment of mutual settlements by withholding
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.PayOffAccountsPayable,
		NStr("vi = 'Số tiền khấu trừ được hướng đến việc thanh toán đối trừ';
			|ru = 'Сумма удержания направляется на погашение взаиморасчетов';
			|en = 'The amount of deduction is directed to the mutual settlements repayment'; fa = 'The amount of deduction is directed to the mutual settlements repayment';
			|it = 'L''importo della trattenuta viene destinato all''estinzione di regolamenti reciproci';
			|pl = 'Wartość potrącenia jest skierowana na umorzenie rozliczeń wzajemnych';
			|tr = 'Stopaj tutarı mutabakat yapılması için kullanılır'"),
		"Counterparty, ARAPObject");
	
	Counterparty = OptionDetails.AttributeProperties.Counterparty; // See PropertiesOfReflectionProps
	Counterparty.Main = True;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Repayment of settlements with the accountable person
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.PayOffAdvanceHolderAccountsPayable,
		NStr("vi = 'Số tiền khấu trừ được hướng đến giảm hạch toán với người nhận tạm ứng';
			|ru = 'Сумма удержания направляется на погашение расчетов с подотчетным лицом';
			|en = 'The amount of deduction is directed to the settlement repayment with advance holder'; fa = 'The amount of deduction is directed to the settlement repayment with advance holder';
			|it = 'L''importo della trattenuta viene destinato all''estinzione di regolamenti con la persona responsabile';
			|pl = 'Wartość potrąceń jest skierowana na umorzenie rozliczeń z zaliczkobiorcą';
			|tr = 'Stopaj tutarı, sorumlu kişiye ödenecek hesapları kapatmak için kullanılır'"),
		"IssuancePurpose");
	
	IssuancePurpose = OptionDetails.AttributeProperties.IssuancePurpose; // See PropertiesOfReflectionProps
	IssuancePurpose.Used = GetFunctionalOption("ControlIssueOfCashByPurposes");
	IssuancePurpose.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// 
	
	Return New FixedMap(ReflectionOptions);
	
EndFunction

//-- WE

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of Structure  - names of blocked Bank details:
//		* ItIsADeduction - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	AttributesToLock = New Array;
	AttributesToLock.Add("ItIsADeduction; ItemKind");
	
	Return AttributesToLock;
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// Called when you first fill in the list of types of Deductionsreferences.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set of details
//                                 in the reference list of types of Deductionsreferences.
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
	Item.PredefinedDataName = "Wage";
	Item.Description = NStr("vi = 'Thanh toán khoán';
							|ru = 'Сдельная оплата';
							|en = 'Wage'; fa = 'Wage';
							|it = 'Pagamento a cottimo';
							|pl = 'Wynagrodzenie akordowe';
							|tr = 'Parça başı ödeme'", Common.DefaultLanguageCode());
	Item.ItIsADeduction = False;
	
	//++ WE
	Item.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth;
	//-- WE
	
EndProcedure

#EndRegion

#Region Private

//++ WE
Function NewVersionOfReflection(Value, LongDesc, Attributes)
	
	PostingOption = New Structure;
	
	PostingOption.Insert("Value", Value);
	PostingOption.Insert("OptionDetails", LongDesc);
	
	PostingOption.Insert("Used", True);
	
	PostingOption.Insert("Attributes", Attributes);
	
	AttributesList = New Array;
	AttributeProperties = New Structure;
	For Each ListItem In StrSplit(Attributes, ",") Do
		AttributeName = TrimAll(ListItem);
		AttributeProperties.Insert(AttributeName, PropertiesOfReflectionProps());
		AttributesList.Add(AttributeName);
	EndDo;
	
	PostingOption.Insert("TemplateOfPresentation", "[" + StrConcat(AttributesList, "][") + "]");
	PostingOption.Insert("AttributeProperties", New FixedStructure(AttributeProperties));
	PostingOption.Insert("CheckFilling", True);
	
	Return PostingOption;
	
EndFunction

// Properties of the reflection props
//
// Returns:
//  Structure - Empty Structure:
//    * Used - Boolean - indication of the use of props for the reflection option,
//    * AttributeIsRequired - Boolean - a sign of mandatory filling,
//    * Main - Boolean - basic Attributes.
//
Function PropertiesOfReflectionProps()
	
	PropsProperties = New Structure;
	PropsProperties.Insert("Used", True);
	PropsProperties.Insert("AttributeIsRequired", True);
	PropsProperties.Insert("Main", False);
	
	Return PropsProperties;
	
EndFunction

//-- WE

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.AccrualAndDeductionKinds.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("425efdec-dd67-4da7-b1c4-181c742da33f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.AccrualAndDeductionKinds.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Dạng tính lương và các khoản trích theo lương"":';
								|ru = 'Обновление справочника ""Виды начислений и удержаний"":';
								|en = 'Update the ""Accrual and deduction kinds"" catalog:'; fa = 'Update the ""Accrual and deduction kinds"" catalog:';
								|it = 'Update the ""Accrual and deduction kinds"" catalog:';
								|pl = 'Update the ""Accrual and deduction kinds"" catalog:';
								|tr = '""Tahakkuk ve kesinti türleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin danh mục đa ngôn ngữ';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.AccrualAndDeductionKinds.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.AccrualAndDeductionKinds.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.AccrualAndDeductionKinds.FullName());
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
	|	AccrualAndDeductionKinds.Ref AS Ref
	|FROM
	|	Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
	|WHERE
	|	NOT AccrualAndDeductionKinds.Description = """"
	|	AND AccrualAndDeductionKinds.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	AccrualAndDeductionKinds.Ref AS Ref
	|FROM
	|	Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
	|WHERE
	|	NOT AccrualAndDeductionKinds.Description = """"
	|	AND AccrualAndDeductionKinds.DescriptionLanguage2 = """"";
	
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
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Dạng tính lương và các khoản trích theo lương"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Виды начислений и удержаний"" по обработчику:';
								|en = 'Cannot process the ""Accrual and deduction kinds"" catalog by the handler:'; fa = 'Cannot process the ""Accrual and deduction kinds"" catalog by the handler:';
								|it = 'Cannot process the ""Accrual and deduction kinds"" catalog by the handler:';
								|pl = 'Cannot process the ""Accrual and deduction kinds"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Tahakkuk ve kesinti türleri"" kataloğu işlenemedi:'"));
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
	|	AccrualAndDeductionKinds.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
	|		ON TT.Ref = AccrualAndDeductionKinds.Ref";
	
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