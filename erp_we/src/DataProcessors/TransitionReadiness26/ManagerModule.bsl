#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns an indication that outdated functionality is being used when checking the notification output.
//
// Returns:
//  Boolean - indicates that the system is using outdated functionality.
//
Function CheckUseOfOutdatedFunctionality() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() Then
		OutdatedFunctionalityIsUsedInSystem = False;
	Else
	
		OutdatedFunctionalityIsUsedInSystem = OutdatedFunctionalityIsUsed();
			
		If Not OutdatedFunctionalityIsUsedInSystem Then
			SetNotificationConstantForOutdatedFunctionality(False);
		EndIf;
		
	EndIf;
		
	SetPrivilegedMode(False);
		
	Return OutdatedFunctionalityIsUsedInSystem;

EndFunction

// Returns an indication that outdated functionality is being used in privileged mode.
//
// Returns:
//  Boolean - indicates that the system is using outdated functionality.
//
Function OutdatedFunctionalityIsUsed() Export
	
	SetPrivilegedMode(True);
	OutdatedFunctionalityIsUsed = False
		
		
		
		
		Or LimitControlStepUsesOutdatedFunctionality()
		
		Or RouteMapsStepUsesOutdatedFunctionality()
		Or CommissionSalesStepUsesOutdatedFunctionality()
		Or PricingStepUsesOutdatedFunctionality()
		Or StepOfARAPAccountingUsesOutdatedFunctionality()
		
		
		Or RLSStepUsesDeprecatedFunctionality();
		
	SetPrivilegedMode(False);
		
	Return OutdatedFunctionalityIsUsed;

EndFunction

// Returns a table of values with outdated functionality.
//
// Parameters:
// 	CalculateState - Boolean
// 	
// Returns:
//  ValueTable:
//   * Id - Number
//   * Outdated_Functionality - String
//   * NewFunctionality - String
//   * Status - Number
//   * State - String
//   * Recommendation - String
//   * Action - String
//   * ModeOfAction - Number
//   * OutdatedFunctionalityIsUsed - Boolean
//   * NewFunctionalityIsUsed - Boolean
//   * RecommendationRequiringAction - Boolean
//   * InformationThatDoesNotContributeToUpdate - Boolean
//   * DocumentDate - Date
//   * ItIsRequiredToCalculateState - Boolean
//
Function TableOfOutdatedFunctionality(CalculateState) Export
	
	SetPrivilegedMode(True);
	
	Table = New ValueTable;
	Table.Columns.Add("Id", Common.TypeDescriptionNumber(2));
	Table.Columns.Add("Outdated_Functionality", Common.StringTypeDetails(200));
	Table.Columns.Add("NewFunctionality", Common.StringTypeDetails(200));
	Table.Columns.Add("Status", Common.TypeDescriptionNumber(1));
	Table.Columns.Add("State", Common.StringTypeDetails(100));
	Table.Columns.Add("Recommendation", Common.StringTypeDetails(0));
	Table.Columns.Add("Action", Common.StringTypeDetails(100));
	Table.Columns.Add("ModeOfAction", Common.TypeDescriptionNumber(1));
	Table.Columns.Add("OutdatedFunctionalityIsUsed", New TypeDescription("Boolean"));
	Table.Columns.Add("NewFunctionalityIsUsed", New TypeDescription("Boolean"));
	Table.Columns.Add("RecommendationRequiringAction", New TypeDescription("Boolean"));
	Table.Columns.Add("InformationThatDoesNotContributeToUpdate", New TypeDescription("Boolean"));
	Table.Columns.Add("DocumentDate", Common.DateTypeDetails(DateFractions.Date));
	Table.Columns.Add("ItIsRequiredToCalculateState", New TypeDescription("Boolean"));
	Table.Columns.Add("ThereIsDataOnOutdatedFunctionality", New TypeDescription("Boolean"));
	
	//
	
	
	AddRouteMapsStep(Table, CalculateState);
	AddSalesCommissionStep(Table, CalculateState);
	AddPricingStep(Table, CalculateState);
	AddStepOfARAPAccounting(Table, CalculateState);
	
	
	
	AddLimitControlStep(Table, CalculateState);
	AddStepOfEnteringBalances(Table, CalculateState);
	AddRLSStep(Table, CalculateState);
	
	SetPrivilegedMode(False);
	
	Return Table;

EndFunction

// Receiving data in a long-term operation.
//
// Parameters:
// 	Parameters - Structure
// 	StorageAddress - String
//
Procedure GettingDataFromOutdatedFunctionalityInBackground(Parameters, StorageAddress) Export
	
	DataTable = TableOfOutdatedFunctionality(True);
	
	PutToTempStorage(DataTable, StorageAddress);
	
EndProcedure

// Sets the constant value for displaying the notification form about outdated functionality.
//
// Parameters:
//  Value - Boolean - set value.
//
Procedure SetNotificationConstantForOutdatedFunctionality(Value) Export

	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() Then
		Return;
	Else
		Constants.NotifyAboutOutdatedFunctionality.Set(Value);
	EndIf;
	
	SetPrivilegedMode(False);

EndProcedure


#EndRegion

#Region Private

Function ModeOfActionTransitionToAssistant()

	Return 1;

EndFunction

Function ModeOfActionTransitionToSection()

	Return 2;

EndFunction

Function ActionModeGoToListOfDocuments()

	Return 3;

EndFunction

Function ActionModeGoToSettings()

	Return 4;

EndFunction

Function PictureInformation()

	Return 2;	

EndFunction

Function PictureDone()

	Return 0;	

EndFunction

Function PictureNeedsAttention()

	Return 1;

EndFunction

Function PictureNotUsed()

	Return 3;	

EndFunction

Procedure FillInDataInLine(String)
	
	OnlyNewFunctionalityIsUsed = Not String.OutdatedFunctionalityIsUsed And String.NewFunctionalityIsUsed;
	FunctionalityIsNotUsed = Not String.OutdatedFunctionalityIsUsed And Not String.NewFunctionalityIsUsed;
	ThereIsDataOnOutdatedFunctionality = String.ThereIsDataOnOutdatedFunctionality;
	
	#Region State
	YouCanGoTo26 = String.InformationThatDoesNotContributeToUpdate Or OnlyNewFunctionalityIsUsed Or FunctionalityIsNotUsed;
		
	If YouCanGoTo26 Then
		StateText = NStr("vi = 'Có thể chuyển sang phiên bản 11.6';
						|ru = 'Можно переходить на редакцию 11.6';
						|en = 'You can migrate to version 11.6'; fa = 'You can migrate to version 11.6';
						|it = 'You can migrate to version 11.6';
						|pl = 'You can migrate to version 11.6';
						|tr = '11.6 sürümüne geçiş yapılabilir'");
		StateText = NStr("vi = 'Có thể chuyển sang phiên bản 2.6';
						|ru = 'Можно переходить на редакцию 2.6';
						|en = 'You can migrate to version 2.6'; fa = 'You can migrate to version 2.6';
						|it = 'You can migrate to version 2.6';
						|pl = 'You can migrate to version 2.6';
						|tr = '2.6 revizyonuna geçilebilir'");
	Else
		StateText = NStr("vi = 'Không thể chuyển sang phiên bản 11.6';
						|ru = 'Нельзя переходить на редакцию 11.6';
						|en = 'You cannot migrate to version 11.6'; fa = 'You cannot migrate to version 11.6';
						|it = 'You cannot migrate to version 11.6';
						|pl = 'You cannot migrate to version 11.6';
						|tr = '11.6 sürümüne geçiş yapılamaz'");
		StateText = NStr("vi = 'Không thể chuyển sang phiên bản 2.6';
						|ru = 'Нельзя переходить на редакцию 2.6';
						|en = 'You cannot migrate to version 2.6'; fa = 'You cannot migrate to version 2.6';
						|it = 'You cannot migrate to version 2.6';
						|pl = 'You cannot migrate to version 2.6';
						|tr = '2.6 revizyonuna geçilemez'");
	EndIf;
	
	If String.ItIsRequiredToCalculateState Then
		StateText = NStr("vi = 'Đang tính';
						|ru = 'Рассчитывается';
						|en = 'Calculating'; fa = 'در حال محاسبه';
						|it = 'Calculating';
						|pl = 'Calculating';
						|tr = 'Hesaplanıyor'");
	EndIf;
	
	String.State = StateText;
	#EndRegion
	
	#Region Recommendation
	Recommendation = String.Recommendation;
	
	If Not String.ItIsRequiredToCalculateState Then
	
		If OnlyNewFunctionalityIsUsed
		 Or FunctionalityIsNotUsed Then
			Recommendation = NStr("vi = 'Không cần thao tác bổ sung.';
									|ru = 'Дополнительных действий не требуется.';
									|en = 'No additional actions are required.'; fa = 'No additional actions are required.';
									|it = 'No additional actions are required.';
									|pl = 'No additional actions are required.';
									|tr = 'Ek işlem gerekmiyor.'");
		ElsIf String.ModeOfAction = ModeOfActionTransitionToAssistant() Then
			Recommendation = NStr("vi = 'Hãy sử dụng trợ lý chuyển.';
									|ru = 'Воспользуйтесь помощником перехода.';
									|en = 'Use the migration wizard.'; fa = 'Use the migration wizard.';
									|it = 'Use the migration wizard.';
									|pl = 'Use the migration wizard.';
									|tr = 'Geçiş sihirbazını kullanın.'");
		EndIf;
	
	EndIf;
	
	String.Recommendation = Recommendation;
	#EndRegion
	
	#Region StatusPicture
	If FunctionalityIsNotUsed And ThereIsDataOnOutdatedFunctionality Then
		String.Status = PictureDone();
	ElsIf FunctionalityIsNotUsed And Not ThereIsDataOnOutdatedFunctionality Then
		String.Status = PictureNotUsed();
	ElsIf String.InformationThatDoesNotContributeToUpdate And Not OnlyNewFunctionalityIsUsed Then
		String.Status = PictureInformation();
	ElsIf OnlyNewFunctionalityIsUsed Then
		String.Status = PictureDone();
	Else
		String.Status = PictureNeedsAttention();
	EndIf;
	#EndRegion
	
	#Region Action
	If Not String.ItIsRequiredToCalculateState Then
	
		If OnlyNewFunctionalityIsUsed Or FunctionalityIsNotUsed Then
			ActionText = "";
		ElsIf String.ModeOfAction = ModeOfActionTransitionToAssistant() Then
			ActionText = NStr("vi = 'Trợ lý chuyển';
								|ru = 'Помощник перехода';
								|en = 'Migration wizard'; fa = 'Migration wizard';
								|it = 'Migration wizard';
								|pl = 'Migration wizard';
								|tr = 'Geçiş sihirbazı'");
		ElsIf String.ModeOfAction = ActionModeGoToListOfDocuments() Then
			ActionText = NStr("vi = 'Chuyển đến danh sách chứng từ';
								|ru = 'Переход к списку документов';
								|en = 'Go to the document list'; fa = 'Go to the document list';
								|it = 'Go to the document list';
								|pl = 'Go to the document list';
								|tr = 'Belge listesine geçiş'");
		ElsIf String.ModeOfAction = ModeOfActionTransitionToSection() Then
			ActionText = NStr("vi = 'Chuyển đến phần quản trị';
								|ru = 'Переход к разделу администрирования';
								|en = 'Go to the Administration section'; fa = 'Go to the Administration section';
								|it = 'Go to the Administration section';
								|pl = 'Go to the Administration section';
								|tr = 'Yönetim bölümüne geçiş'");
		ElsIf String.ModeOfAction = ActionModeGoToSettings() Then
			ActionText = NStr("vi = 'Chuyển đến tùy chỉnh';
								|ru = 'Переход к настройке';
								|en = 'Go to setting'; fa = 'Go to setting';
								|it = 'Go to setting';
								|pl = 'Go to setting';
								|tr = 'Ayarlama adımına geçiş'");
		EndIf;
	
	EndIf;
	
	String.Action = ActionText;
	#EndRegion
	
	#Region RecommendationRequiringAction
	If OnlyNewFunctionalityIsUsed Or FunctionalityIsNotUsed Then
		String.RecommendationRequiringAction = False;
	EndIf;
	#EndRegion
	
EndProcedure




#Region ControlOfLimits

Procedure AddLimitControlStep(Table, CalculateState)
	
	String = Table.Add();
	String.Id = StepControlLimitsId();
	String.Outdated_Functionality = NStr("vi = 'Kiểm soát hạn mức 2.4';
										|ru = 'Контроль лимитов 2.4';
										|en = 'Limit control 2.4'; fa = 'Limit control 2.4';
										|it = 'Limit control 2.4';
										|pl = 'Limit control 2.4';
										|tr = 'Limit kontrolü 2.4'");
	String.NewFunctionality = NStr("vi = 'Kiểm soát hạn mức 2.5';
									|ru = 'Контроль лимитов 2.5';
									|en = 'Limit control 2.5'; fa = 'Limit control 2.5';
									|it = 'Limit control 2.5';
									|pl = 'Limit control 2.5';
									|tr = 'Limit kontrolü 2.5'");
	String.ModeOfAction = ModeOfActionTransitionToSection();
	
	String.ItIsRequiredToCalculateState = Not CalculateState;
	If CalculateState Then
	
		String.OutdatedFunctionalityIsUsed = LimitControlStepUsesOutdatedFunctionality();
		String.NewFunctionalityIsUsed = LimitControlStepUsesNewFunctionality();
	
	EndIf;
	
	String.Recommendation = NStr("vi = 'Để chuyển sang chức năng mới, cần chuyển đổi tùy chọn chức năng.';
								|ru = 'Для перехода на новую функциональность необходимо переключить функциональную опцию.';
								|en = 'To migrate to the new functionality, enable the functional option.'; fa = 'To migrate to the new functionality, enable the functional option.';
								|it = 'To migrate to the new functionality, enable the functional option.';
								|pl = 'To migrate to the new functionality, enable the functional option.';
								|tr = 'Yeni işlevselliğe geçmek için fonksiyonel seçeneği değiştirmeniz gerekiyor.'");
	
	FillInDataInLine(String);

EndProcedure

Function StepControlLimitsId() Export

	Return 11;

EndFunction

Function LimitControlStepUsesOutdatedFunctionality()

	Return GetFunctionalOption("UseBudgetingCashFlowLimits") 
		And GetFunctionalOption("ControllingLimitsBasedOnBudgetingData2_4");

EndFunction

Function LimitControlStepUsesNewFunctionality()

	Return GetFunctionalOption("UseBudgetingCashFlowLimits") 
		And Not GetFunctionalOption("ControllingLimitsBasedOnBudgetingData2_4");

EndFunction

#EndRegion


#Region RouteSheets

Procedure AddRouteMapsStep(Table, CalculateState)
	
	String = Table.Add();
	String.Id = RouteMapsIdStep();
	String.Outdated_Functionality = NStr("vi = 'Sơ đồ quy trình';
										|ru = 'Маршрутные карты';
										|en = 'Route sheets'; fa = 'برگه‌های مسیر';
										|it = 'Route sheets';
										|pl = 'Route sheets';
										|tr = 'Rotalar'");
	String.NewFunctionality = NStr("vi = 'Thao tác trong các bảng kê chi tiết các nguồn lực sản xuất';
									|ru = 'Операции в производственных спецификациях';
									|en = 'Operations in BOMs'; fa = 'Operations in BOMs';
									|it = 'Operations in BOMs';
									|pl = 'Operations in BOMs';
									|tr = 'Üretim ürün reçetelerindeki işlemler'");
	String.ModeOfAction = ModeOfActionTransitionToAssistant();
	
	String.ItIsRequiredToCalculateState = Not CalculateState;
	If CalculateState Then
	
		String.OutdatedFunctionalityIsUsed = RouteMapsStepUsesOutdatedFunctionality();
		String.NewFunctionalityIsUsed = RouteMapsStepUsesNewFunctionality();
		String.DocumentDate = RouteMapsStepIsDateOfLastDocument();
		String.ThereIsDataOnOutdatedFunctionality = ValueIsFilled(String.DocumentDate);
	
	EndIf;
	
	String.Recommendation = NStr("vi = 'Hãy sử dụng trợ lý chuyển.';
								|ru = 'Воспользуйтесь помощником перехода.';
								|en = 'Use the migration wizard.'; fa = 'Use the migration wizard.';
								|it = 'Use the migration wizard.';
								|pl = 'Use the migration wizard.';
								|tr = 'Geçiş sihirbazını kullanın.'");
	
	FillInDataInLine(String);

EndProcedure

Function RouteMapsIdStep() Export

	Return 4;

EndFunction

Function RouteMapsStepUsesOutdatedFunctionality()

	Return GetFunctionalOption("UseProduction") And Not GetFunctionalOption("StoreOperationsInBillsOfMaterials");

EndFunction

Function RouteMapsStepUsesNewFunctionality()

	Return GetFunctionalOption("UseProduction") And GetFunctionalOption("StoreOperationsInBillsOfMaterials");

EndFunction

Function RouteMapsStepIsDateOfLastDocument()
	
	Date = Date(1, 1, 1); 
	
	Query = New Query(RouteMapsQueryTextStepIsDateOfLastDocument());
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.DocumentDate;
	EndIf;
	
	Return Date;

EndFunction

Function RouteMapsQueryTextStepIsDateOfLastDocument()

	Return 
	"SELECT
	|	MAX(NestedQuery.Date) AS DocumentDate
	|FROM
	|	(SELECT
	|		MAX(Table.Date) AS Date
	|	FROM
	|		Document.ProductionStage2_2 AS Table
	|			LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|			ON Table.Ref = TechnicalProcess.Stage
	|			FULL JOIN Constant.StoreOperationsInBillsOfMaterials AS Option
	|			ON (TRUE)
	|	WHERE
	|		Table.Posted
	|		AND CASE Option.Value
	|				WHEN TRUE
	|					THEN ISNULL(TechnicalProcess.TechnologicalProcess, UNDEFINED) REFS Catalog.RouteSheets
	|							AND ISNULL(TechnicalProcess.TechnologicalProcess, UNDEFINED) <> VALUE(Catalog.RouteSheets.EmptyRef)
	|				ELSE Table.Stage.RouteSheet <> VALUE(Catalog.RouteSheets.EmptyRef)
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MAX(Table.Date)
	|	FROM
	|		Document.ProductionOperation2_2 AS Table
	|	WHERE
	|		Table.Posted
	|		AND Table.Operation.Owner REFS Catalog.RouteSheets) AS NestedQuery";

EndFunction

#EndRegion

#Region ConsignmentSales

Procedure AddSalesCommissionStep(Table, CalculateState)
	
	String = Table.Add();
	String.Id = StepCommissionSalesId();
	String.Outdated_Functionality = NStr("vi = 'Bán hàng ký gửi, phiên bản 11.0';
										|ru = 'Комиссионные продажи, версия 11.0';
										|en = 'Consignment sales, version 11.0'; fa = 'Consignment sales, version 11.0';
										|it = 'Consignment sales, version 11.0';
										|pl = 'Consignment sales, version 11.0';
										|tr = 'Konsinye satışlar, sürüm 11.0'");
	String.NewFunctionality = NStr("vi = 'Bán hàng ký gửi, phiên bản 11.5';
									|ru = 'Комиссионные продажи, версия 11.5';
									|en = 'Consignment sales, version 11.5'; fa = 'Consignment sales, version 11.5';
									|it = 'Consignment sales, version 11.5';
									|pl = 'Consignment sales, version 11.5';
									|tr = 'Konsinye satışlar, sürüm 11.5'");
	String.RecommendationRequiringAction = True;
	String.ModeOfAction = ActionModeGoToListOfDocuments();
	
	String.ItIsRequiredToCalculateState = Not CalculateState;
	If CalculateState Then
	
		String.OutdatedFunctionalityIsUsed = CommissionSalesStepUsesOutdatedFunctionality();
		String.NewFunctionalityIsUsed = CommissionSalesStepUsesNewFunctionality();
		String.DocumentDate = StepCommissionSalesDateOfLastDocument();
		String.ThereIsDataOnOutdatedFunctionality = ValueIsFilled(String.DocumentDate);
	
	EndIf;
	
	String.Recommendation = NStr("vi = 'Để chuyển sang chức năng ""Bán hàng ký gửi, phiên bản 11.5"", cần thực hiện các bước sau:
		|1. Tạo hợp đồng mới chuyển sang ký gửi có chỉ định phiên bản 11.5 trong các hợp đồng đó (việc sử dụng hợp đồng là bắt buộc). Tạo các thỏa thuận mới, nếu có sử dụng.
		|2. Các chứng từ chưa được lập (Bảng kê hàng bán của người nhận ký gửi) trong phạm vi thỏa thuận và hợp đồng của phiên bản 11.0 - hoàn thiện theo phiên bản 11.0
		|3. Đối với các hàng hóa còn lại, lập trả lại theo phiên bản 11.0 và chuyển tiếp theo theo phiên bản 11.5.
		|4. Trong tùy chỉnh bán hàng ký gửi, chọn phiên bản 11.5 thay cho 11.0/11.5.';
		|ru = 'Для перехода на функциональность ""Комиссионные продажи, версия 11.5"" необходимо выполнить следующие шаги:
		|1. Создать новые договоры передачи на комиссию с указанием в них версии 11.5 (использование договоров обязательно). Создать новые соглашения, если используются.
		|2. Недооформленные документы (отчеты комиссионеров) в рамках соглашений и договоров версии 11.0 - дооформить по версии 11.0.
		|3. Для остающихся товаров оформить возвраты по версии комиссии 11.0  и последующую передачу по версии 11.5.
		|4. В настройках комиссионных продаж выбрать версию 11.5 взамен 11.0/11.5.';
		|en = 'To migrate to the ""Consignment sales, version 11.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 11.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 11.0 in accordance with version 11.0.
		|3. For remaining items, issue returns under consignment sales version 11.0 and subsequent transfer under version 11.5.
		|4. In the consignment sales settings, select version 11.5 instead of 11.0/11.5.'; fa = 'To migrate to the ""Consignment sales, version 11.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 11.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 11.0 in accordance with version 11.0.
		|3. For remaining items, issue returns under consignment sales version 11.0 and subsequent transfer under version 11.5.
		|4. In the consignment sales settings, select version 11.5 instead of 11.0/11.5.';
		|it = 'To migrate to the ""Consignment sales, version 11.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 11.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 11.0 in accordance with version 11.0.
		|3. For remaining items, issue returns under consignment sales version 11.0 and subsequent transfer under version 11.5.
		|4. In the consignment sales settings, select version 11.5 instead of 11.0/11.5.';
		|pl = 'To migrate to the ""Consignment sales, version 11.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 11.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 11.0 in accordance with version 11.0.
		|3. For remaining items, issue returns under consignment sales version 11.0 and subsequent transfer under version 11.5.
		|4. In the consignment sales settings, select version 11.5 instead of 11.0/11.5.';
		|tr = '""Konsinye satışlar, sürüm 11.5"" işlevselliğine geçmek için aşağıdaki adımları izleyin:
		|1. İçinde 11.5 sürümü belirtilen yeni konsinye satış sözleşmeleri oluşturun (sözleşme kullanımı zorunludur). Kullanılıyorsa yeni anlaşmalar oluşturun.
		|2. 11.0 sürümlü anlaşma ve sözleşmeler kapsamındaki düzenleme durumunda olan belgeleri (konsinye bildirimleri) 11.0 sürümüne göre düzenleyin.
		|3. Kalan ürünler için konsinyenin 11.0 sürümüne göre iadeler ve ardından 11.5 sürümüne göre transferler düzenleyin.
		|4. Konsinye satış ayarlarında 11.0/11.5 sürümü yerine 11.5 sürümünü seçin.'");
	String.Outdated_Functionality = NStr("vi = 'Bán hàng ký gửi, phiên bản 2.0';
										|ru = 'Комиссионные продажи, версия 2.0';
										|en = 'Consignment sales, version 2.0'; fa = 'Consignment sales, version 2.0';
										|it = 'Consignment sales, version 2.0';
										|pl = 'Consignment sales, version 2.0';
										|tr = 'Konsinye satışlar, sürüm 2.0'");
	String.NewFunctionality = NStr("vi = 'Bán hàng ký gửi, phiên bản 2.5';
									|ru = 'Комиссионные продажи, версия 2.5';
									|en = 'Consignment sales, version 2.5'; fa = 'Consignment sales, version 2.5';
									|it = 'Consignment sales, version 2.5';
									|pl = 'Consignment sales, version 2.5';
									|tr = 'Konsinye satışlar, sürüm 2.5'");
	String.Recommendation = NStr("vi = 'Để chuyển sang chức năng ""Bán hàng ký gửi, phiên bản 2.5"", cần thực hiện các bước sau:
		|1. Tạo hợp đồng mới chuyển sang ký gửi có chỉ định phiên bản 2.5 trong các hợp đồng đó (việc sử dụng hợp đồng là bắt buộc). Tạo các thỏa thuận mới, nếu có sử dụng.
		|2. Các chứng từ chưa được lập (Bảng kê hàng bán của người nhận ký gửi) trong phạm vi thỏa thuận và hợp đồng của phiên bản 2.0 - hoàn thiện theo phiên bản 2.0
		|3. Đối với các hàng hóa còn lại, lập trả lại theo phiên bản 2.0 và chuyển tiếp theo theo phiên bản 2.5.
		|4. Trong tùy chỉnh bán hàng ký gửi, chọn phiên bản 2.5 thay cho 2.0/2.5.';
		|ru = 'Для перехода на функциональность ""Комиссионные продажи, версия 2.5"" необходимо выполнить следующие шаги:
		|1. Создать новые договоры передачи на комиссию с указанием в них версии 2.5 (использование договоров обязательно). Создать новые соглашения, если используются.
		|2. Недооформленные документы (отчеты комиссионеров) в рамках соглашений и договоров версии 2.0 - дооформить по версии 2.0.
		|3. Для остающихся товаров оформить возвраты по версии комиссии 2.0  и последующую передачу по версии 2.5.
		|4. В настройках комиссионных продаж выбрать версию 2.5 взамен 2.0/2.5.';
		|en = 'To migrate to the ""Consignment sales, version 2.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 2.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 2.0 in accordance with version 2.0.
		|3. For remaining items, issue returns under consignment sales version 2.0 and subsequent transfer under version 2.5.
		|4. In the consignment sales settings, select version 2.5 instead of 2.0/2.5.'; fa = 'To migrate to the ""Consignment sales, version 2.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 2.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 2.0 in accordance with version 2.0.
		|3. For remaining items, issue returns under consignment sales version 2.0 and subsequent transfer under version 2.5.
		|4. In the consignment sales settings, select version 2.5 instead of 2.0/2.5.';
		|it = 'To migrate to the ""Consignment sales, version 2.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 2.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 2.0 in accordance with version 2.0.
		|3. For remaining items, issue returns under consignment sales version 2.0 and subsequent transfer under version 2.5.
		|4. In the consignment sales settings, select version 2.5 instead of 2.0/2.5.';
		|pl = 'To migrate to the ""Consignment sales, version 2.5"" functionality, do the following:
		|1. Create new consignment sales contracts with version 2.5 (contract is required). Create new terms of sales if used.
		|2. Complete unfinished documents (consignment issue notifications) under terms of sales and contracts version 2.0 in accordance with version 2.0.
		|3. For remaining items, issue returns under consignment sales version 2.0 and subsequent transfer under version 2.5.
		|4. In the consignment sales settings, select version 2.5 instead of 2.0/2.5.';
		|tr = '""Konsinye satışlar, sürüm 2.5"" işlevselliğine geçmek için aşağıdaki adımları izleyin:
		|1. İçinde 2.5 sürümü belirtilen yeni konsinye satış sözleşmeleri oluşturun (sözleşme kullanımı zorunludur). Kullanılıyorsa yeni anlaşmalar oluşturun.
		|2. 2.0 sürümlü anlaşma ve sözleşmeler kapsamındaki düzenleme durumunda olan belgeleri (konsinye bildirimleri) 2.0 sürümüne göre düzenleyin.
		|3. Kalan ürünler için konsinyenin 2.0 sürümüne göre iadeler ve ardından 2.5 sürümüne göre transferler düzenleyin.
		|4. Konsinye satış ayarlarında 2.0/2.5 sürümü yerine 2.5 sürümünü seçin.'");
	FillInDataInLine(String);

EndProcedure

Function StepCommissionSalesId() Export

	Return 5;

EndFunction

Function CommissionSalesStepUsesOutdatedFunctionality()
	
	ValueOfOptions = GetFunctionalOption("UseSalesCommission") And GetFunctionalOption("SelectConsignmentSalesVersion");
	
	If ValueOfOptions Then
		Return True;
	Else
		Return SalesCommissionStepHasBalancesInFinancialAccounting();
	EndIf;
	
EndFunction

Function CommissionSalesStepUsesNewFunctionality()

	Return GetFunctionalOption("UseSalesCommission") And Not GetFunctionalOption("SelectConsignmentSalesVersion");

EndFunction

Function StepCommissionSalesDateOfLastDocument()
	
	Date = Date(1, 1, 1); 
	
	Query = New Query(StepCommissionSalesQueryTextDateOfLastDocument());
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.DocumentDate;
	EndIf;
	
	Return Date;

EndFunction

Function StepCommissionSalesQueryTextDateOfLastDocument()

	Return 
	"SELECT
	|	MAX(Table.Date) AS DocumentDate
	|FROM
	|	(SELECT
	|		MAX(GoodsTransferred.Period) AS Date
	|	FROM
	|		AccumulationRegister.GoodsTransferredToCommissionAgent AS GoodsTransferred
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MAX(References.Date)
	|	FROM
	|		Document.SalesOrder AS References
	|	WHERE
	|		References.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|		AND References.Posted
	|		AND NOT ISNULL(References.Contract.ConsignmentSales25, FALSE)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MAX(References.Date)
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS References
	|	WHERE
	|		References.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|		AND References.Posted
	|		AND NOT ISNULL(References.Contract.ConsignmentSales25, FALSE)) AS Table";

EndFunction

Function SalesCommissionStepHasBalancesInFinancialAccounting()

	Query = New Query;
	Query.Text = 
		"SELECT
		|	References.ReferenceOrder AS ReferenceOrder
		|FROM
		|	InformationRegister.ShipmentAndReturnReferencesToFulfill AS References
		|WHERE
		|	References.DocumentStateToRegister <> VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|	AND References.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|	AND NOT ISNULL(References.ReferenceOrder.Contract.ConsignmentSales25, FALSE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsTransferred.Terms AS Terms,
		|	GoodsTransferred.Organization AS Organization,
		|	GoodsTransferred.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GoodsTransferred.CCDNumber AS CCDNumber,
		|	GoodsTransferred.CountBalance AS CountBalance,
		|	GoodsTransferred.QuantityByGBRNBalance AS QuantityByGBRNBalance
		|FROM
		|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(, ) AS GoodsTransferred
		|WHERE
		|	(GoodsTransferred.CountBalance <> 0
		|			OR GoodsTransferred.QuantityByGBRNBalance <> 0)";
	
	ResultsArray = Query.ExecuteBatch();
	Return Not ResultsArray[0].IsEmpty() Or Not ResultsArray[1].IsEmpty();

EndFunction

#EndRegion

#Region PriceManagementSystem

Procedure AddPricingStep(Table, CalculateState)
	
	String = Table.Add();
	String.Id = StepPricingId();
	String.Outdated_Functionality = NStr("vi = 'Thiết lập giá, phiên bản 11.0';
										|ru = 'Ценообразование, версия 11.0';
										|en = 'Pricing, version 11.0'; fa = 'Pricing, version 11.0';
										|it = 'Pricing, version 11.0';
										|pl = 'Pricing, version 11.0';
										|tr = 'Fiyatlandırma, sürüm 11.0'");
	String.NewFunctionality = NStr("vi = 'Thiết lập giá, phiên bản 11.5';
									|ru = 'Ценообразование, версия 11.5';
									|en = 'Pricing, version 11.5'; fa = 'Pricing, version 11.5';
									|it = 'Pricing, version 11.5';
									|pl = 'Pricing, version 11.5';
									|tr = 'Fiyatlandırma, sürüm 11.5'");
	String.ModeOfAction = ModeOfActionTransitionToAssistant();
	
	String.ItIsRequiredToCalculateState = Not CalculateState;
	If CalculateState Then
	
		String.OutdatedFunctionalityIsUsed = PricingStepUsesOutdatedFunctionality();
		String.NewFunctionalityIsUsed = PricingStepUsesNewFunctionality();
		String.DocumentDate = PricingStepIsDateOfLastDocument();
		String.ThereIsDataOnOutdatedFunctionality = ValueIsFilled(String.DocumentDate);
	
	EndIf;
	
	String.Recommendation = NStr("vi = 'Hãy sử dụng trợ lý chuyển.';
								|ru = 'Воспользуйтесь помощником перехода.';
								|en = 'Use the migration wizard.'; fa = 'Use the migration wizard.';
								|it = 'Use the migration wizard.';
								|pl = 'Use the migration wizard.';
								|tr = 'Geçiş sihirbazını kullanın.'");
	String.Outdated_Functionality = NStr("vi = 'Thiết lập giá, phiên bản 2.0';
										|ru = 'Ценообразование, версия 2.0';
										|en = 'Pricing, version 2.0'; fa = 'Pricing, version 2.0';
										|it = 'Pricing, version 2.0';
										|pl = 'Pricing, version 2.0';
										|tr = 'Fiyatlandırma, sürüm 2.0'");
	String.NewFunctionality = NStr("vi = 'Thiết lập giá, phiên bản 2.5';
									|ru = 'Ценообразование, версия 2.5';
									|en = 'Pricing, version 2.5'; fa = 'Pricing, version 2.5';
									|it = 'Pricing, version 2.5';
									|pl = 'Pricing, version 2.5';
									|tr = 'Fiyatlandırma, sürüm 2.5'");
	FillInDataInLine(String);

EndProcedure

Function StepPricingId() Export

	Return 6;

EndFunction

Function PricingStepUsesOutdatedFunctionality()

	Return GetFunctionalOption("UseSeveralPriceTypes") And GetFunctionalOption("UsePriceManagementSystem20");

EndFunction

Function PricingStepUsesNewFunctionality()

	Return GetFunctionalOption("UseSeveralPriceTypes") And GetFunctionalOption("UsePriceManagementSystem25");

EndFunction

Function PricingStepIsDateOfLastDocument()
	
	Date = Date(1, 1, 1); 
	
	Query = New Query(PricingStepQueryTextDateOfLastDocument());
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.DocumentDate;
	EndIf;
	
	Return Date;

EndFunction

Function PricingStepQueryTextDateOfLastDocument()

	Return 
	"SELECT
	|	MAX(Period) AS DocumentDate
	|FROM
	|	InformationRegister.ItemsPrices AS ItemsPrices";

EndFunction
	
#EndRegion

#Region ARAPAccounting

Procedure AddStepOfARAPAccounting(Table, CalculateState)
	
	String = Table.Add();
	String.Id = StepOfARAPAccountingId();
	String.Outdated_Functionality = NStr("vi = 'Kiến trúc hạch toán công nợ ""Cũ"" (""ngoại tuyến"")';
										|ru = '""Старая"" архитектура взаиморасчетов (""оффлайн"")';
										|en = '""Old"" AR/AP configuration (""offline"")'; fa = '""Old"" AR/AP configuration (""offline"")';
										|it = '""Old"" AR/AP configuration (""offline"")';
										|pl = '""Old"" AR/AP configuration (""offline"")';
										|tr = '""Eski"" alacak/borç yapılandırması (""çevrimdışı"")'");
	String.NewFunctionality = NStr("vi = 'Kiến trúc hạch toán công nợ ""Mới"" (""trực tuyến"")';
									|ru = '""Новая"" архитектура взаиморасчетов (""онлайн"")';
									|en = '""New"" AR/AP configuration (""online"")'; fa = '""New"" AR/AP configuration (""online"")';
									|it = '""New"" AR/AP configuration (""online"")';
									|pl = '""New"" AR/AP configuration (""online"")';
									|tr = '""Yeni"" alacak/borç yapılandırması (""çevrimiçi"")'");
	String.ModeOfAction = ModeOfActionTransitionToSection();
	
	String.ItIsRequiredToCalculateState = Not CalculateState;
	If CalculateState Then
	
		String.OutdatedFunctionalityIsUsed = StepOfARAPAccountingUsesOutdatedFunctionality();
		String.NewFunctionalityIsUsed = StepOfARAPAccountingUsesNewFunctionality();
	
	EndIf;
	
	String.Recommendation = NStr("vi = 'Để chuyển sang chức năng mới, cần chuyển đổi tùy chọn chức năng.';
								|ru = 'Для перехода на новую функциональность необходимо переключить функциональную опцию.';
								|en = 'To migrate to the new functionality, enable the functional option.'; fa = 'To migrate to the new functionality, enable the functional option.';
								|it = 'To migrate to the new functionality, enable the functional option.';
								|pl = 'To migrate to the new functionality, enable the functional option.';
								|tr = 'Yeni işlevselliğe geçmek için fonksiyonel seçeneği değiştirmeniz gerekiyor.'");
	
	FillInDataInLine(String);

EndProcedure

Function StepOfARAPAccountingId() Export

	Return 7;

EndFunction

Function StepOfARAPAccountingUsesOutdatedFunctionality()

	Return Not GetFunctionalOption("NewOnlineARAPAccounting");

EndFunction

Function StepOfARAPAccountingUsesNewFunctionality()

	Return GetFunctionalOption("NewOnlineARAPAccounting");

EndFunction

#EndRegion


#Region OBEntry

Procedure AddStepOfEnteringBalances(Table, CalculateState)
	
	String = Table.Add();
	String.Id = StepEnterBalanceId();
	String.Outdated_Functionality = NStr("vi = 'Chứng từ duy nhất ""Nhập số dư""';
										|ru = 'Единый документ ""Ввод остатков""';
										|en = 'Unified ""OB entry"" document'; fa = 'Unified ""OB entry"" document';
										|it = 'Unified ""OB entry"" document';
										|pl = 'Unified ""OB entry"" document';
										|tr = 'Tek ""Bakiye girişi"" belgesi'");
	String.NewFunctionality = NStr("vi = 'Chứng từ riêng biệt ""Nhập số dư""';
									|ru = 'Раздельные документы ""Ввод остатков""';
									|en = 'Separate ""OB entry"" documents'; fa = 'Separate ""OB entry"" documents';
									|it = 'Separate ""OB entry"" documents';
									|pl = 'Separate ""OB entry"" documents';
									|tr = 'Ayrı ""Bakiye girişi"" belgeleri'");
	String.OutdatedFunctionalityIsUsed = False;
	String.NewFunctionalityIsUsed = False;
	String.InformationThatDoesNotContributeToUpdate = True;
	String.ItIsRequiredToCalculateState = Not CalculateState;
	
	String.Recommendation = NStr("vi = 'Không cần thao tác bổ sung.';
								|ru = 'Дополнительных действий не требуется.';
								|en = 'No additional actions are required.'; fa = 'No additional actions are required.';
								|it = 'No additional actions are required.';
								|pl = 'No additional actions are required.';
								|tr = 'Ek işlem gerekmiyor.'");
	
	FillInDataInLine(String);

EndProcedure

Function StepEnterBalanceId() Export

	Return 12;

EndFunction

#EndRegion

#Region RLS

Procedure AddRLSStep(Table, CalculateState)
	
	String = Table.Add();
	String.Id = RLSIdStep();
	String.Outdated_Functionality = NStr("vi = 'RLS ""Chuẩn""';
										|ru = '""Стандартный"" RLS';
										|en = '""Standard"" RLS'; fa = '""Standard"" RLS';
										|it = '""Standard"" RLS';
										|pl = '""Standard"" RLS';
										|tr = '""Standart"" RLS'");
	String.NewFunctionality = NStr("vi = 'RLS ""Hiệu suất""';
									|ru = '""Производительный"" RLS';
									|en = '""Performance"" RLS'; fa = '""Performance"" RLS';
									|it = '""Performance"" RLS';
									|pl = '""Performance"" RLS';
									|tr = '""Yüksek performanslı"" RLS'");
	String.InformationThatDoesNotContributeToUpdate = True;
	String.ModeOfAction = ModeOfActionTransitionToSection();
	
	String.ItIsRequiredToCalculateState = Not CalculateState;
	If CalculateState Then
	
		String.OutdatedFunctionalityIsUsed = RLSStepUsesDeprecatedFunctionality();
		String.NewFunctionalityIsUsed = RLSStepUsesNewFunctionality();
	
	EndIf;
	
	String.Recommendation = NStr("vi = 'Trong phiên bản 11.5, bạn nên chuyển sang chế độ ""Hiệu suất"" của RLS. Trong phiên bản 11.6, sẽ bắt buộc chuyển đổi.';
								|ru = 'Рекомендуется заранее выполнить переход на ""Производительный"" режим RLS в редакции 11.5. В редакции 11.6 переход будет принудительным.';
								|en = 'It is recommended that you migrate to ""Performance"" RLS mode in version 11.5 in advance. In version 11.6, the migration is required.'; fa = 'It is recommended that you migrate to ""Performance"" RLS mode in version 11.5 in advance. In version 11.6, the migration is required.';
								|it = 'It is recommended that you migrate to ""Performance"" RLS mode in version 11.5 in advance. In version 11.6, the migration is required.';
								|pl = 'It is recommended that you migrate to ""Performance"" RLS mode in version 11.5 in advance. In version 11.6, the migration is required.';
								|tr = '11.5 revizyonunda RLS''nin ""Yüksek performanslı"" moduna geçiş önceden yapmanız önerilir. 11.6 revizyonunda geçiş zorunlu olacaktır.'");
	String.Recommendation = NStr("vi = 'Trong phiên bản 2.5, bạn nên chuyển sang chế độ ""Hiệu suất"" của RLS. Trong phiên bản 2.6, sẽ bắt buộc chuyển đổi.';
								|ru = 'Рекомендуется заранее выполнить переход на ""Производительный"" режим RLS в редакции 2.5. В редакции 2.6 переход будет принудительным.';
								|en = 'It is recommended that you migrate to ""Performance"" RLS mode in version 2.5 in advance. In version 2.6, the migration is required.'; fa = 'It is recommended that you migrate to ""Performance"" RLS mode in version 2.5 in advance. In version 2.6, the migration is required.';
								|it = 'It is recommended that you migrate to ""Performance"" RLS mode in version 2.5 in advance. In version 2.6, the migration is required.';
								|pl = 'It is recommended that you migrate to ""Performance"" RLS mode in version 2.5 in advance. In version 2.6, the migration is required.';
								|tr = '2.5 revizyonunda RLS''nin ""Yüksek performanslı"" moduna geçiş önceden yapmanız önerilir. 2.6 revizyonunda geçiş zorunlu olacaktır.'");
	FillInDataInLine(String);

EndProcedure

Function RLSIdStep() Export

	Return 13;

EndFunction

Function RLSStepUsesDeprecatedFunctionality()

	Return GetFunctionalOption("LimitAccessAtRecordLevel") And Not GetFunctionalOption("LimitAccessAtRecordLevelUniversally");

EndFunction

Function RLSStepUsesNewFunctionality()

	Return GetFunctionalOption("LimitAccessAtRecordLevel") And GetFunctionalOption("LimitAccessAtRecordLevelUniversally");

EndFunction
	
#EndRegion

#EndRegion

#EndIf
