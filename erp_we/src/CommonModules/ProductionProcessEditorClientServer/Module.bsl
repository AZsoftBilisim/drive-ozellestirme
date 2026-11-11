////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the Production Process Editor
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region ProductionStage

// Sets the availability of stage duration details
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ElementPrefix - String - element prefix
Procedure ConfigureGroupItemsStageDuration(Object, Form, ElementPrefix = "") Export
	
	Items = Form.Items;
	
	DurationViewOnly = CalculateDurationAutomatically(Object,
		Form.ProductionIsUsed21,
		Form.PlanningByMaterialResourcesIsUsed,
		Form.PlanningByProductionResourcesIsUsed);
	
	MatchingElements = MatchingElements(ElementPrefix);
	
	Items[MatchingElements.StageDuration].ReadOnly                 = DurationViewOnly;
	Items[MatchingElements.UnitOfMeasureOfStageDuration].ReadOnly = DurationViewOnly;
	
EndProcedure

// Sets the availability and other settings of the route map details
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ElementPrefix - String - element prefix
Procedure ConfigureRouteMapGroupElements(Object, Form, ElementPrefix = "") Export
	
	Items = Form.Items;
	
	DisplayCoefficient = 
		Form.ProductionIsUsed22
		And Form.UseRouteSheets
		And Not Form.ProductionIsUsed21;
	
	MatchingElements = MatchingElements(ElementPrefix);
	
	Items[MatchingElements.RouteSheetFactor].Visible = DisplayCoefficient;
	Items[MatchingElements.RouteSheetFactor].AutoMarkIncomplete = ValueIsFilled(Object.RouteSheet);
	Items[MatchingElements.RouteSheetFactor].ReadOnly = Not Form.AttributeAvailability
		Or Form.BillOfMaterialsIsClosed
		Or Not ValueIsFilled(Object.RouteSheet);
		
	Items[MatchingElements.CalculateOperationsSheetFactor].Visible = DisplayCoefficient;
	
	Items[MatchingElements.CalculateOperationsSheetFactor].Enabled = DisplayCoefficient
		And Not Items[MatchingElements.RouteSheetFactor].ReadOnly
		And Form[MatchingElements.CalculateFactor];
	
	Items[MatchingElements.PagesSplitRouteSheets].CurrentPage =
		?(ValueIsFilled(Object.RouteSheet),
			Items[MatchingElements.PageSplitRouteSheetsUsingOperationsSheet],
			Items[MatchingElements.PageSplitRouteSheets]);
			
EndProcedure

Function GetRouteMapSettings(Object) Export
	
	Result = New Structure;
	
	If ValueIsFilled(Object.RouteSheet) Then
		
		MKDetails = ProductDataManagementServerCall.RouteCardDetailsValues(Object.RouteSheet);
		
		Result.Insert("CalculateFactor", MKDetails.CalculateFactor);
		Result.Insert("SplitRouteSheetsByRouteMap", MKDetails.MaximumNumberOfProductUnitsLots <> 0);
		
	Else
		
		Result.Insert("CalculateFactor", False);
		Result.Insert("SplitRouteSheets", Object.MaximumNumberOfProductUnitsLots <> 0);
		Result.Insert("MaximumNumberOfProductUnitsLots", Object.MaximumNumberOfProductUnitsLots);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Determines the availability of the process editor for the stage
// 
// Parameters:
//  Data_Stage - Structure
// 
// Returns:
//  Boolean - editor availability
Function ProcessTechnologyEditorIsAvailable(Data_Stage) Export
	
	Result = Not Data_Stage.ProductionByThirdParty
		And Data_Stage.Posted
		And Data_Stage.UseOperationManagement
		And Not Data_Stage.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
	
	Return Result;
	
EndFunction

// Fills in the details of explaining the stage settings
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ElementPrefix - String - element prefix
Procedure FillInExplanationOfBasicSettings(Object, Form, ElementPrefix = "") Export
	
	RowsArray = New Array;
	
	Items = Form.Items;
	
	MatchingElements = MatchingElements(ElementPrefix);
	
	Production21 = Form.ProductionIsUsed21;
	PlanningForProductionResources_ = Form.PlanningByProductionResourcesIsUsed;
	PlanForMaterialResources = Form.PlanningByMaterialResourcesIsUsed;
	UseVRC = Object.PlanOperationsOfWorkCenterTypes;
	UseProductionPlans = Form.UseProductionPlanning;
	ProductionByThirdParty = Not (Form[MatchingElements.ProductionMethod] = 0);
	DynamicStructureOfProductionOrders = Form.DynamicStructureOfProductionOrders;
	
	If (Not PlanningForProductionResources_ And PlanForMaterialResources)
		And Production21
		And UseVRC Then
		
		RowsArray.Add(
			NStr("vi = 'Dạng nguồn lực sản xuất được sử dụng để tạo lịch biểu có tính đến mức độ khả dụng (trong quản lý sản xuất phiên bản 2.1).';
				|ru = 'Виды рабочих центров используются для построения графика с учетом доступности (в управлении производством версии 2.1).';
				|en = 'Work center types are used to create a schedule considering capacity (in Production management, version 2.1).'; fa = 'Work center types are used to create a schedule considering capacity (in Production management, version 2.1).';
				|it = 'I tipi dei centri di lavoro sono utilizzati per costruire un programma produttivo basato sulla disponibilità (nella versione 2.1 della gestione della produzione).';
				|pl = 'Rodzaje centrów wykonania pracy są używane do tworzenia harmonogramu z uwzględnieniem dostępności (w zarządzaniu produkcją wersji 2.1).';
				|tr = 'İş merkezi türleri, kullanılabilirliğe dayalı bir program oluşturmak için kullanılmaktadır (2.1 sürümü üretim yönetiminde).'"));
		
		RowsArray.Add(
			NStr("vi = 'Thời lượng của công đoạn được dùng để thiết lập lịch biểu sản xuất (trong quản lý sản xuất phiên bản 2.2).';
				|ru = 'Длительность этапа используется для построения графика производства (в управлении производством версии 2.2).';
				|en = 'Stage duration is used to create a production schedule (in Production management, version 2.2).'; fa = 'Stage duration is used to create a production schedule (in Production management, version 2.2).';
				|it = 'La lunghezza della fase viene utilizzata per costruire un programma produttivo (nella versione 2.2 della gestione della produzione).';
				|pl = 'Czas trwania etapu jest wykorzystywany do tworzenia harmonogramu produkcji (w zarządzaniu produkcją wersji 2.2).';
				|tr = 'Aşama süresi, üretim programı oluşturmak için kullanılmaktadır (2.2 sürümü üretim yönetiminde).'"));
		
	Else
		
		If (PlanningForProductionResources_ Or Production21) And UseVRC Then
			
			RowsArray.Add(
				NStr("vi = 'Dạng nguồn lực sản xuất được dùng để tạo lịch biểu dựa trên mức độ khả dụng.';
					|ru = 'Виды рабочих центров используются для построения графика с учетом доступности.';
					|en = 'Work center types are used to create a schedule considering capacity.'; fa = 'Work center types are used to create a schedule considering capacity.';
					|it = 'I tipi dei centri di lavoro sono utilizzati per costruire un programma produttivo basato sulla disponibilità.';
					|pl = 'Rodzaje centrów wykonania pracy są używane do tworzenia harmonogramu z uwzględnieniem dostępności.';
					|tr = 'İş merkezi türleri, kullanılabilirliğe dayalı bir program oluşturmak için kullanılmaktadır.'"));
		
		ElsIf DynamicStructureOfProductionOrders And UseVRC Then
			
			RowsArray.Add(
				NStr("vi = 'Dạng nguồn lực sản xuất được sử dụng để tính toán lịch biểu định mức trong cấu trúc đơn hàng sản xuất động.';
					|ru = 'Виды рабочих центров используются для расчета нормативного графика динамической структуры заказов на производство.';
					|en = 'Use work center types to calculate the standard schedule for the dynamic structure of production orders.'; fa = 'Use work center types to calculate the standard schedule for the dynamic structure of production orders.';
					|it = 'Виды рабочих центров используются для расчета нормативного графика динамической структуры заказов на производство.';
					|pl = 'Use work center types to calculate the standard schedule for the dynamic structure of production orders.';
					|tr = 'İş merkezi türleri, üretim emirlerinin dinamik yapısına yönelik standart programı hesaplamak için kullanılmaktadır.'"));
			
		ElsIf UseProductionPlans And UseVRC Then
			
			RowsArray.Add(
				NStr("vi = 'Dạng nguồn lực sản xuất được dùng để tính toán nhu cầu theo kế hoạch sản xuất.';
					|ru = 'Виды рабочих центров используются для расчета потребностей по планам производства.';
					|en = 'Work center types are used to calculate demand according to production plans.'; fa = 'Work center types are used to calculate demand according to production plans.';
					|it = 'I tipi dei centri di lavoro sono utilizzati per calcolare le esigenze in base ai piani di produzione.';
					|pl = 'Rodzaje centrów wykonania pracy są używane do rozliczania zapotrzebowania wg planów produkcji.';
					|tr = 'İş merkezi türleri, üretim planlarına yönelik gereksinimleri hesaplamak için kullanılmaktadır.'"));
				
		ElsIf UseVRC Then
			
			RowsArray.Add(NStr("vi = 'Các dạng nguồn lực sản xuất được đặt trong danh mục.';
								|ru = 'Виды рабочих центров задаются справочно.';
								|en = 'Work center types are set for reference.'; fa = 'Work center types are set for reference.';
								|it = 'I tipi dei centri di lavoro sono impostati per riferimento.';
								|pl = 'Rodzaje centrów są określane informacyjnie.';
								|tr = 'İş merkezi türleri referans olarak belirtilmektedir.'"));
			
		EndIf;
		
		If (
				(PlanningForProductionResources_ Or Production21)
				And Not UseVRC
			)
			Or (
					Not PlanningForProductionResources_ And PlanForMaterialResources
				)
			Or ProductionByThirdParty Then
			
			RowsArray.Add(
				NStr("vi = 'Thời lượng công đoạn được dùng để thiết lập lịch biểu sản xuất.';
					|ru = 'Длительность этапа используется для построения графика производства.';
					|en = 'Stage duration is used to create a production schedule.'; fa = 'Stage duration is used to create a production schedule.';
					|it = 'La durata della fase viene utilizzata per costruire un programma di produzione.';
					|pl = 'Czas trwania etapu jest używany do tworzenia harmonogramu produkcji.';
					|tr = 'Aşama süresi, üretim programı oluşturmak için kullanılmaktadır.'"));
			
		ElsIf PlanningForProductionResources_ And UseVRC Then
			
			RowsArray.Add(
				NStr("vi = 'Thời lượng của công đoạn được dùng để xác định thời hạn sản xuất sản phẩm mà không cần đặt lịch biểu.';
					|ru = 'Длительность этапа используется для определения сроков изготовления продукции без построения графика.';
					|en = 'Stage duration is used to determine product manufacturing deadlines without making a schedule.'; fa = 'Stage duration is used to determine product manufacturing deadlines without making a schedule.';
					|it = 'La durata della fase viene utilizzata per determinare i tempi di produzione senza costruire un programma di produzione.';
					|pl = 'Czas trwania etapu jest używany do określania terminów wytworzenia produkcji bez tworzenia harmonogramu.';
					|tr = 'Aşama süresi, program oluşturmadan imal edilen ürünlerin üretim zamanlamasını belirlemek için kullanılmaktadır.'"));
			
		ElsIf UseProductionPlans Then
			
			RowsArray.Add(
				NStr("vi = 'Thời lượng công đoạn được dùng để tính toán lịch biểu sản xuất.';
					|ru = 'Длительность этапа используется для расчета планов производства.';
					|en = 'Step duration is used to calculate production plans.'; fa = 'Step duration is used to calculate production plans.';
					|it = 'Длительность этапа используется для расчета планов производства.';
					|pl = 'Step duration is used to calculate production plans.';
					|tr = 'Aşama süresi, üretim planlarının hesaplanması için kullanılmaktadır.'"));
			
		EndIf;
		
	EndIf;
	
	If (PlanningForProductionResources_ Or PlanForMaterialResources) And ProductionByThirdParty Then
		
		RowsArray.Add(
			NStr("vi = 'Sẽ lập kế hoạch sản xuất theo lịch làm việc của doanh nghiệp.';
				|ru = 'Планирование производства будет происходить по графику работы предприятия.';
				|en = 'Production planning will occur according to the enterprise work schedule.'; fa = 'Production planning will occur according to the enterprise work schedule.';
				|it = 'Programmazione della produzione verrà effettuata in base al grafico di lavoro dell''azienda.';
				|pl = 'Planowanie produkcji będzie odbywać się zgodnie z harmonogramem pracy przedsiębiorstwa.';
				|tr = 'Üretim planlaması, işletmenin çalışma takvimine göre gerçekleşecektir.'"));
		
	EndIf;
	
	If CalculateDurationAutomatically(Object,
		Production21,
		PlanForMaterialResources,
		PlanningForProductionResources_) Then
		
		RowsArray.Add(
				NStr("vi = 'Thời lượng được tính tự động theo dung lượng bộ đệm trung gian và thời gian làm việc của các dạng nguồn lực sản xuất.';
					|ru = 'Длительность рассчитывается автоматически по размеру буферов и времени работы видов рабочих центров.';
					|en = 'Duration is calculated automatically according to the buffer size and working hours of work center types.'; fa = 'Duration is calculated automatically according to the buffer size and working hours of work center types.';
					|it = 'La durata viene calcolata automaticamente in base alla dimensione dei buffer e all''orario di lavoro dei tipi di centri di lavoro.';
					|pl = 'Czas trwania jest rozliczany automatycznie wg wielkości buforów i czasu pracy rodzajów centrów pracy.';
					|tr = 'Süre, panoların boyutuna ve iş merkezi türlerinin çalışma süresine göre otomatik olarak hesaplanmaktadır.'"));
		
	EndIf;
	
	GroupRemark = Items[MatchingElements.GroupDuration];
	GroupRemark.ToolTip = ?(RowsArray.UBound() <> -1, StrConcat(RowsArray, Chars.LF), "");
	
EndProcedure

Function MandatoryFillingOfUnitsOfMeasurementOfBuffers(Object) Export
	
	Result = New Structure;
	Result.Insert("UnitOfMeasureOfPreliminaryBuffer", False);
	Result.Insert("UnitOfMeasureOfFollowUpBuffer", False);
	
	If Not ValueIsFilled(Object.UnitOfMeasureOfPreliminaryBuffer)
		And Object.PreliminaryBuffer <> 0 Then
		Result.UnitOfMeasureOfPreliminaryBuffer = True;
	EndIf;
	
	If Not ValueIsFilled(Object.UnitOfMeasureOfFollowUpBuffer)
		And Object.FollowUpBuffer <> 0 Then
		Result.UnitOfMeasureOfFollowUpBuffer = True;
	EndIf;
	
	Return Result;
	
EndFunction

Function CalculateDurationAutomatically(Object,
	ProductionIsUsed21,
	PlanningByMaterialResourcesIsUsed,
	PlanningByProductionResourcesIsUsed) Export
	
	Return Object.PlanOperationsOfWorkCenterTypes
		And ProductionIsUsed21
		And Not PlanningByMaterialResourcesIsUsed
		And Not PlanningByProductionResourcesIsUsed;
	
EndFunction

// The text of the message to the user about the need to switch the process technology to an individual mode.
// 
// Returns:
//  String
Function TextSwitchProcessTechnologyToIndividualMode() Export
	
	Return NStr("vi = 'Để thêm giao dịch, cần chuyển quy trình công nghệ của công đoạn sang chế độ riêng biệt.';
				|ru = 'Для добавления операции, технологический процесс этапа необходимо переключить в индивидуальный режим.';
				|en = 'To add an operation, switch the technological process of the stage to individual mode.'; fa = 'To add an operation, switch the technological process of the stage to individual mode.';
				|it = 'To add an operation, switch the technological process of the stage to individual mode.';
				|pl = 'To add an operation, switch the technological process of the stage to individual mode.';
				|tr = 'İşlem eklemek için aşamanın teknolojik süreci özelleştirilmiş moda değiştirilmelidir.'");
	
EndFunction

#Region WorkCenterTypes

// Performs standard actions when entering a new line of types of work centers
// - sets the number of alternative types of work centers.
//
// Parameters:
//  RowData						- FormDataStructure - contains string data
//  Copy							- Boolean - True if the string is being copied
//  AlternateWorkCenterTypes	- TabularSection - a table containing PM data of "Alternative types of work centers".
//
Procedure WhenEnteringNewLineOfTypesOfWorkCenters(RowData, Copy, AlternateWorkCenterTypes = Undefined) Export

	If Not Copy And Not ValueIsFilled(RowData.UnitOfMeasure) Then
		
		RowData.UnitOfMeasure  = ProductDataManagementClientServer.BasicUnitOfTime();
		
	EndIf;
	
EndProcedure

Procedure CalculateServiceSignsOfLoadingVRC(WorkCenterTypes, ThereIsParallelDownload = Undefined, ThereIsSynchronousLoad = Undefined) Export
	
	ThereIsParallelDownload = False;
	ThereIsSynchronousLoad = False;
	
	For Each MainVRC In WorkCenterTypes.GetItems() Do
		
		If ThereIsParallelDownload And ThereIsSynchronousLoad Then
			Break;
		EndIf;
		
		If MainVRC.ParallelLoad Then
			ThereIsParallelDownload = True;
			If MainVRC.SynchronousLoad Then
				ThereIsSynchronousLoad = True;
			EndIf;
		EndIf;
		
		For Each AlternativeVRC In MainVRC.GetItems() Do
			
			If AlternativeVRC.ParallelLoad Then
				ThereIsParallelDownload = True;
				If AlternativeVRC.SynchronousLoad Then
					ThereIsSynchronousLoad = True;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Sets the availability and other settings of the load switch for several types of work centers 
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ElementPrefix - String - element prefix
Procedure ConfigureOrderOfWorkCenterViewsElement(Object, Form, ElementPrefix = "") Export
	
	Items = Form.Items;
	
	FormAttributes = New Structure("Mode");
	FillPropertyValues(FormAttributes, Form); 
	
	VisibilityOfOrderOfOperationOfVRC = Object.PlanOperationsOfWorkCenterTypes
		And Form.ProductionIsUsed22
		And (Not Form.DynamicStructureOfProductionOrders
				Or ValueIsFilled(Object.OperatingProcedureOfWorkCenterTypes) 
						And Object.OperatingProcedureOfWorkCenterTypes <> PredefinedValue("Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously"))
		And FormAttributes.Mode <> "OrderSpecification";
	
	MatchingElements = MatchingElements(ElementPrefix);
	
	If VisibilityOfOrderOfOperationOfVRC Then
		
		SeveralTypesOfRC = Form[MatchingElements.WorkCenterTypes].GetItems().Count() > 1;
		
		If SeveralTypesOfRC Then
			Items[MatchingElements.OperatingProcedureOfWorkCenterTypes].InputHint = "";
		Else
			Items[MatchingElements.OperatingProcedureOfWorkCenterTypes].InputHint = NStr("vi = '<không sử dụng>';
																						|ru = '<не используется>';
																						|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																						|it = '<non viene utilizzato>';
																						|pl = '<nie używa się>';
																						|tr = '<kullanılmayan>'");
		EndIf;
		
		If Form.AttributeAvailability And Not Form.BillOfMaterialsIsClosed Then
			Items[MatchingElements.OperatingProcedureOfWorkCenterTypes].ReadOnly = Not SeveralTypesOfRC;
		EndIf;
		
	EndIf;
	
	Items[MatchingElements.OperatingProcedureOfWorkCenterTypes].Visible = VisibilityOfOrderOfOperationOfVRC;
	
EndProcedure

// Sets the availability of the simultaneously produced quantity field
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ElementPrefix - String - element prefix
Procedure ConfigureItemSimultaneouslyProducedQuantity(Object, Form, ElementPrefix = "") Export
	
	MatchingElements = MatchingElements(ElementPrefix);
	
	Form.Items[MatchingElements.QuantityOfProductUnitsLotsProducedSimultaneously].ReadOnly
		= Not SimultaneouslyProducedQuantityIsAvailable(
					Form.DynamicStructureOfProductionOrders,
					Form[MatchingElements.ThereIsParallelDownload]);
	
EndProcedure

// Cleans simultaneously produced quantity if it is not available
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ElementPrefix - String - element prefix
Procedure CheckPurifySimultaneouslyProducedQuantity(Object, Form, ElementPrefix = "") Export
	
	MatchingElements = MatchingElements(ElementPrefix);
	
	If Not SimultaneouslyProducedQuantityIsAvailable(
					Form.DynamicStructureOfProductionOrders,
					Form[MatchingElements.ThereIsParallelDownload]) Then
		Object.QuantityOfProductUnitsLotsProducedSimultaneously = 0;
	EndIf;
	
EndProcedure

// Determines the availability of simultaneously produced quantity settings
// 
// Parameters:
//  DynamicStructureOfProductionOrders - Boolean - A dynamic order structure is used
//  ThereIsParallelDownload - Boolean - there is a VRC with parallel loading
// 
// Returns:
//  Boolean - Simultaneously produced number of units of Lot reference products is available
Function SimultaneouslyProducedQuantityIsAvailable(DynamicStructureOfProductionOrders, ThereIsParallelDownload) Export
	
	Return Not DynamicStructureOfProductionOrders
		Or Not ThereIsParallelDownload;
	
EndFunction

// Configures the elements of the "Types of Work Centers" page" 
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ElementPrefix - String - element prefix
Procedure ConfigureElementsOfWorkCenterViewsGroup(Object, Form, ElementPrefix = "") Export
	
	Items = Form.Items;
	
	OwnProduction = Not Object.ProductionByThirdParty;
		
	UseVRC = Object.PlanOperationsOfWorkCenterTypes;
	
	Planning22 = Form.ProductionIsUsed22
		And Form.PlanningByProductionResourcesIsUsed;
	
	PlanningForLoadingVRC = UseVRC
		And (Planning22 Or Form.ProductionIsUsed21 Or Form.DynamicStructureOfProductionOrders);
	
	MatchingElements = MatchingElements(ElementPrefix);
	
	Items[MatchingElements.PageTypesOfWorkCenters].Visible = UseVRC;
	
	If UseVRC Then
		
		Items[MatchingElements.WorkCenterTypes].Visible = True;
		
		Items[MatchingElements.TheGroupAtTheSameTimeTheProducedQuantity].Visible = True;
		
		Items[MatchingElements.PlanningInterval].Visible = PlanningForLoadingVRC
			And OwnProduction;
			
		Items[MatchingElements.BuffersGroup].Visible = PlanningForLoadingVRC And OwnProduction;
		
		Items[MatchingElements.Continuous_].Visible = PlanningForLoadingVRC
			And OwnProduction;
		ProductionProcessEditorClientServer.ConfigureOrderOfWorkCenterViewsElement(Object, Form, ElementPrefix);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region TechnologicalOperation

Function WorkCenterType(WorkCenter) Export
	
	If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenterTypes") Then
		
		Return WorkCenter;
		
	Else
		
		Return GeneralPurposeTMServerCall.ObjectAttributeValue(WorkCenter, "WorkCenterType");
		
	EndIf;
	
EndFunction

// Fills in the transfer batch unit of measurement
// 
// Parameters:
// 	Object - CatalogObject.ManufacturingOperations
// 	UnitOfMeasureOfTransferBatch - String
Procedure FillInUnitOfMeasurementOfTransferBatch(Object, UnitOfMeasureOfTransferBatch) Export
	
	If Object.TransferLot = 0 Then
		UnitOfMeasureOfTransferBatch = NStr("vi = 'chuyển giao toàn bộ lô hàng của công đoạn';
											|ru = 'передается вся партия этапа';
											|en = 'whole stage lot is transferred'; fa = 'whole stage lot is transferred';
											|it = 'viene trasmesso l''intero lotto della fase';
											|pl = 'jest przekazywana cała partia etapu';
											|tr = 'aşamanın tüm lotu transfer edilmektedir'");
	Else
		UnitOfMeasureOfTransferBatch = " * " + 
			Object.Count + ?(ValueIsFilled(Object.UnitOfMeasure), " " + 
			ProductionManagementClientServer.PresentationOfUnitOfOperation(
				Object.UnitOfMeasure, 
				Object.Count), "") + " = " + 
			(Object.TransferLot * Object.Count) + " " +
			ProductionManagementClientServer.PresentationOfUnitOfOperation(
				Object.UnitOfMeasure, 
				Object.TransferLot * Object.Count);
	EndIf;
		
EndProcedure

#Region AdditionalDetailsOfTypeOfOperation

Procedure UploadOperationTypeStandards(Object, AddAttributes) Export
	
	Object.OperationKindStandards.Clear();
	
	For Each String In AddAttributes Do
		If String.ValueMin <> 0 Or String.ValueMax <> 0 Then
			FillPropertyValues(Object.OperationKindStandards.Add(), String, "Property, ValueMin, ValueMax");
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

// Specification of Operation
// 
// Parameters:
//  RowData - FormDataCollectionItem
// 
// Returns:
//  Boolean - This is an NSI Operation
Function ThisIsNSIOperation(RowData) Export
	
	Return RowData <> Undefined
		And ValueIsFilled(RowData.Operation);
	
EndFunction

// Specification of Operation
// 
// Parameters:
//  RowData - FormDataCollectionItem
// 
// Returns:
//  Boolean - This is the Operation of the specification
Function ThisIsOperationOfOperationAccordingToBillOfMaterials(RowData) Export
	
	Return RowData <> Undefined
		And ValueIsFilled(RowData.Operation)
		And Not ValueIsFilled(RowData.TechnologicalProcess);
	
EndFunction

// Specification of Operation
// 
// Parameters:
//  RowData - FormDataCollectionItem
// 
// Returns:
//  Boolean - This is the Operation of the specification
Function ThisIsProcessOperation(RowData) Export
	
	Return RowData <> Undefined
		And ValueIsFilled(RowData.Operation)
		And TypeOf(RowData.TechnologicalProcess) = Type("CatalogRef.TechnologicalProcesses");
	
EndFunction

// Individual OF Operation
// 
// Parameters:
//  RowData - FormDataCollectionItem
// 
// Returns:
//  Boolean - This is an Individual Operation
Function ThisOperationIsIndividual(RowData) Export
	
	Return RowData <> Undefined
		And Not ValueIsFilled(RowData.Operation)
		And RowData.OperationID > 0;
	
EndFunction

// Group of individual Operations
// 
// Parameters:
//  RowData - FormDataCollectionItem
// 
// Returns:
//  Boolean - This is the band
Function ThisIsGroupOfIndividualOperations(RowData) Export
	
	Return RowData <> Undefined
		And Not ValueIsFilled(RowData.Operation)
		And RowData.OperationID = 0;
	
EndFunction

#EndRegion

#Region Other

// Set the image of the element.
// 
// Parameters:
//  RowData - ValueTreeRow:
//  * Ref - CatalogRef.ManufacturingOperations
//  ImagesOfElements - Array of Picture
Procedure SetItemImage(RowData, ImagesOfElements = Undefined) Export
	
	If RowData.ItemKind = TypeOfStageElement() Then
		If RowData.WorkPlanning Then
			PictureIndex = 3;
		Else
			PictureIndex = 0;
		EndIf;
	ElsIf RowData.ItemKind = TypeOfElementOfOperation() Then
		If ValueIsFilled(RowData.TechnologicalProcess) Then
			PictureIndex = 2;
		ElsIf Not ValueIsFilled(RowData.Ref) Then
			PictureIndex = 5;
		Else
			PictureIndex = 1;
		EndIf;
	ElsIf RowData.ItemKind = TypeOfWorkElement() Then
		PictureIndex = 4;
	Else
		Return;
	EndIf;
	
	If ImagesOfElements = Undefined Then
		ImagesOfElements = New Array;
		ImagesOfElements.Add(PictureLib.ManufacturingProcessProductionStage);
		ImagesOfElements.Add(PictureLib.ProductionProcessOperation);
		ImagesOfElements.Add(PictureLib.ManufacturingProcessTechnologicalProcess);
		ImagesOfElements.Add(PictureLib.ManufacturingProcessWorkPlanningStage);
		ImagesOfElements.Add(PictureLib.ManufacturingProcessRMWork);
		ImagesOfElements.Add(PictureLib.ManufacturingProcessDocument);
	EndIf;
	
	RowData.Picture = ImagesOfElements[PictureIndex];
	
EndProcedure

Function MatchingElements(ElementPrefix) Export
	
	Result = New Structure;
	
	If ElementPrefix = "Stage" Or IsBlankString(ElementPrefix) Then
		
		Result.Insert("BuffersGroup",                                          "StageGroupBuffers");
		Result.Insert("GroupDuration",                                    "StageGroupDuration");
		Result.Insert("TheGroupAtTheSameTimeTheProducedQuantity",              "TheGroupStageAtTheSameTimeTheProducedQuantity");
		Result.Insert("PageTypesOfWorkCenters",                            "StagePageTypesOfWorkCenters");
		Result.Insert("PageSplitRouteSheets",                      "StagePageSplitRouteSheets");
		Result.Insert("PagesSplitRouteSheets",                      "PageStageSplitRouteSheets");
		Result.Insert("PageSplitRouteSheetsUsingOperationsSheet",     "StagePageSplitRouteSheetsByRouteMap");
		
		Result.Insert("Continuous_",                                           "ContinuousStage");
		Result.Insert("PlanningInterval",                                  "PlanningIntervalStage");
		
		Result.Insert("WorkCenterTypes",                                    "StageTypesOfWorkCenters");
		
		Result.Insert("OperatingProcedureOfWorkCenterTypes",                      "StageOperatingProcedureOfTheTypesOfWorkCenters");
		Result.Insert("ProductionMethod",                                    "StageProductionMethod");
		Result.Insert("RouteSheetFactor",                            "StageCoefficientOfTheRouteMap");
		Result.Insert("CalculateOperationsSheetFactor",                  "StageCalculateTheCoefficientOfTheRouteMap");
		Result.Insert("CalculateFactor",                               "StepCalculateCoefficient");

		Result.Insert("SplitRouteSheetsByRouteMap",             "StageSplitRouteSheetsByRouteMap");
		Result.Insert("SplitRouteSheets",                              "TheSplitRouteSheetsStage");
		Result.Insert("MaximumNumberOfProductUnitsLots",             "StageMaximumNumberOfUnitsOfProductBatches");
		
		Result.Insert("StageNumber",                                            "StageNumberOfTheStage");
		Result.Insert("NextStageNo",                                  "StageNumberOfTheNextStage");
		Result.Insert("Department",                                         "StageDivision");
		Result.Insert("ProductionMethod",                                    "StageProductionMethod");
		Result.Insert("QuantityOfProductUnitsLotsProducedSimultaneously", "TheStageAtTheSameTimeProduceTheNumberOfUnitsOfProductBatches");
		Result.Insert("PlanOperationsOfWorkCenterTypes",                  "StagePlanTheWorkOfTheTypesOfWorkCenters");
		Result.Insert("WorkCenterTypes",                                    "StageTypesOfWorkCenters");
		Result.Insert("Partner",                                               "PartnerStage");
		Result.Insert("Organization",                                           "StepCompany");
		Result.Insert("SubcontractorServices",                                   "ProcessorServiceStage");
		Result.Insert("WorkScheduleOfPartner",                                  "PartnerSWorkScheduleStage");
		Result.Insert("OperatingProcedureOfWorkCenterTypes",                      "StageOperatingProcedureOfTheTypesOfWorkCenters");
		Result.Insert("FillInTheTypesOfWorkCenters",                           "StageFillInTypesOfWorkCenters");
		Result.Insert("TypesOfWorkCentersAddAlternative",              "StageTypesOfWorkCentersAddAlternative");
		Result.Insert("PreliminaryBuffer",                                  "PreBufferStage");
		Result.Insert("FollowUpBuffer",                                      "TheFinalBufferStage");
		Result.Insert("UnitOfMeasureOfPreliminaryBuffer",                "StagePreBufferUnitOfMeasurement");
		Result.Insert("UnitOfMeasureOfFollowUpBuffer",                    "StageTheUnitOfMeasurementOfTheTerminatingBuffer");
		Result.Insert("StageDuration",                                     "StageDurationOfTheStage");
		Result.Insert("UnitOfMeasureOfStageDuration",                     "StageAUnitOfMeasurementForTheDurationOfAStage");
		
		Result.Insert("ThereIsParallelDownload",                              "StageIsParallelLoading");
		Result.Insert("ThereIsSynchronousLoad",                                "TheStageIsSynchronousLoading");
		
	EndIf;
		
	If ElementPrefix = "Operation" Or IsBlankString(ElementPrefix) Then
		
		Result.Insert("ItemsAvailability",                      "OperationItemAvailability");
		Result.Insert("GroupQuantity",                          "OperationGroupQuantity");
		Result.Insert("GroupExecution",                          "TheGroupOperationExecution");
		Result.Insert("GroupTransferBatch",                  "OperationOfTheTransferGroupParty");
		Result.Insert("AuxiliaryWorkCentersPage",      "OperationPageAuxiliaryWorkCenters");
		
		Result.Insert("AddAttributes",                              "OperationAddAttributes");
		Result.Insert("AdditionalAttributesQuantity",                    "OperationAdditionalDetailsQuantity");
		Result.Insert("AddAttributesValueMin",                   "OperationAddAttributesValueMin");
		Result.Insert("AddAttributesValueMax",                  "OperationAddAttributesValueMax");
		
		Result.Insert("WorkTimeOnSynchronousLoad",          "OperationTimeOperationAtSynchronousLoad");
		Result.Insert("UnitOfMeasureForSynchronousLoad",     "OperationUnitOfMeasurementForSynchronousLoading");
		
		Result.Insert("ProductionArea",                                   "OperationPlot");
		Result.Insert("WorkCenter",                              "OperationWorkCenter");
		Result.Insert("AuxiliaryWorkCenters",              "OperationAuxiliaryWorkCenters");
		Result.Insert("AuxiliaryWorkCentersWorkCenter",  "OperationAuxiliaryWorkCentersWorkCenter");
		
		Result.Insert("Description",                              "OperationName_");
		Result.Insert("CLASSIFIEROFTECHNOLOGICALOPERATIONS",                                       "OperationWHO");
		Result.Insert("OperationKind",                               "OperationTypeOfOperation");
		Result.Insert("OperationNumber",                             "OperationOperationNumber");
		Result.Insert("NextOperation",                    "OperationNextOperation");
		Result.Insert("Count",                                "OperationQuantity");
		Result.Insert("UnitOfMeasure",                          "OperationUnitOfMeasure");
		Result.Insert("TimePerPiece",                              "OperationUnitTime");
		Result.Insert("TimePerPieceUnitOfMeasure",                         "OperationTimePieceUnitIsm");
		Result.Insert("SetupTime",                                   "OperationTimePZ");
		Result.Insert("SetupTimeUnitOfMeasure",                              "OperationTimePZEdIsm");
		Result.Insert("Load",                                  "OperationUpload");
		Result.Insert("UnitOfMeasureOfLoad",                  "OperationDownloadUnitOfMeasurement");
		Result.Insert("Control",                                  "Operation_Control");
		
		Result.Insert("Continuous",                               "OperationIsContinuous");
		Result.Insert("Repeatable",                            "TheOperationCanBeRepeated");
		Result.Insert("Skippable",                           "YouCanSkipTheOperation");
		Result.Insert("SetupSettingsAreUsed",               "OperationSetupOptionsAreUsed");
		Result.Insert("SetupSettings",                            "OperationSetupOption");
		Result.Insert("SynchronousLoad",                        "OperationSynchronousLoading");
		Result.Insert("ParallelLoad",                      "ParallelLoadingOperation");
		
	EndIf;
	
	If IsBlankString(ElementPrefix) Then
		For Each KeyAndValue In Result Do
			Result[KeyAndValue.Key] = KeyAndValue.Key;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

// View of the stage element.
// 
// Returns:
//  String
Function TypeOfStageElement() Export
	
	Return "Stage";
	
EndFunction

// Type of operation element.
// 
// Returns:
//  String
Function TypeOfElementOfOperation() Export
	
	Return "Operation";
	
EndFunction

// View of the work element.
// 
// Returns:
//  String
Function TypeOfWorkElement() Export
	
	Return "Work_5";
	
EndFunction

// Types of elements of the production process
// 
// Returns:
//  Array of String - Types of elements
Function ItemsKinds() Export
	
	Result = New Array;
	
	Result.Add(TypeOfStageElement());
	Result.Add(TypeOfElementOfOperation());
	Result.Add(TypeOfWorkElement());
	Return Result;
	
EndFunction

// Returns the name of the new production process element
// 
// Parameters:
//  ItemKind - String - type of production process element
//  Number - Number - sequence number of the element
// 
// Returns:
//  String - Name Of The New Element
Function NameOfNewItem(ItemKind, Number = 0) Export
	
	Result = "";
	
	If ItemKind = TypeOfStageElement() Then
		Result = NStr("vi = 'Công đoạn';
						|ru = 'Этап';
						|en = 'Stage'; fa = 'مرحله';
						|it = 'Fase';
						|pl = 'Stage';
						|tr = 'Aşama'");
	ElsIf ItemKind = TypeOfElementOfOperation() Then
		Result = NStr("vi = 'Giao dịch';
						|ru = 'Операция';
						|en = 'Operation'; fa = 'عملیات';
						|it = 'Operazione';
						|pl = 'Operacja';
						|tr = 'İşlem'");
	ElsIf ItemKind = TypeOfWorkElement() Then
		Result = NStr("vi = 'Công việc';
						|ru = 'Работа';
						|en = 'Work'; fa = 'کار';
						|it = 'Work';
						|pl = 'Work';
						|tr = 'İş'");
	EndIf;
	
	If Number > 0 Then
		Result = StrTemplate("%1 %2", Result, Number);
	EndIf;
	
	Return Result;
	
EndFunction

// The name of the type of the production process element by reference.
// 
// Parameters:
//  Ref - CatalogRef.ProductionStages
// 
// Returns:
//  Undefined, String, Arbitrary - Name Of The Element Type By Reference
Function NameOfElementTypeByReference(Ref) Export
	
	DataTypes = New Array;
	DataTypes.Add("ProductionStages");
	DataTypes.Add("ManufacturingOperations");
	ElementType = TypeOf(Ref);
	For Each TypeName In DataTypes Do
		If ElementType = Type("CatalogRef."+TypeName) Then
			Return TypeName;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Constructor of the value structure of an element of the production process.
// 
// Returns:
//  Structure - Structure - from:
// * Stage - CatalogRef.ProductionStages
// * StagePresentation - String
Function StructureOfValueOfProductionProcessElementConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("Stage");
	Result.Insert("StagePresentation", "");
	Result.Insert("Operation");
	Result.Insert("OperationPresentation", "");
	Result.Insert("OperationID", 0);
	Result.Insert("ProductionOperation");
	Return Result;
	
EndFunction

Procedure SetPropertyOfFormElements(Items, ElementsToBeProcessed, PropertyName, Value, MatchingElements = Undefined) Export
	
	If TypeOf(ElementsToBeProcessed) = Type("String") Then
		ItemArray = StrSplit(ElementsToBeProcessed, ",");
	Else
		ItemArray = ElementsToBeProcessed;
	EndIf;
	
	For Each TagName In ItemArray Do
		CommonClientServer.SetFormItemProperty(Items,
			?(MatchingElements = Undefined, TagName, MatchingElements[TagName]),
			PropertyName,
			Value);
	EndDo;
	
EndProcedure

// The text of the warning about the impossibility of executing the command
// 
// Parameters:
//  RowsArray - Array of Number
// 
// Returns:
//  String
Function WarningTextCommandCannotBeExecuted(RowsArray = Undefined) Export
	
	If RowsArray <> Undefined And RowsArray.Count() > 1 Then
		Return NStr("vi = 'Lệnh không thể được thực thi cho một hoặc nhiều dòng được chọn.';
					|ru = 'Команда не может быть выполнена для одной или нескольких выбранных строк.';
					|en = 'Command cannot be executed for one or multiple selected lines.'; fa = 'Command cannot be executed for one or multiple selected lines.';
					|it = 'Command cannot be executed for one or multiple selected lines.';
					|pl = 'Command cannot be executed for one or multiple selected lines.';
					|tr = 'Seçilen bir veya daha fazla satır için komut gerçekleştirilemez.'");
	Else
		Return NStr("vi = 'Lệnh không thể được thực thi cho dòng được chọn.';
					|ru = 'Команда не может быть выполнена для выбранной строки.';
					|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
					|it = 'Il comando non può essere eseguito per la riga selezionata.';
					|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
					|tr = 'Seçili satır için komut gerçekleştirilemez.'");
	EndIf;
	
EndFunction

// Constructor of the technological process parameters of the stage
// 
// Returns:
//  Structure - From:
// * TechnologicalProcessType - EnumRef.TechnologicalProcessTypesOfStage
// * TechnologicalProcess - CatalogRef.TechnologicalProcesses,CatalogRef.RouteSheets
// * TechnologicalProcessFactor - Number
// * ThereAreTechnologicalOperations - Boolean 
Function ProcessParametersConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("TechnologicalProcessType", PredefinedValue("Enum.TechnologicalProcessTypesOfStage.Standard"));
	Result.Insert("TechnologicalProcess");
	Result.Insert("TechnologicalProcessFactor", 1);
	
	Result.Insert("ThereAreTechnologicalOperations", False);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Editor

Function ResultOfRecordingTechnicalProcessConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("CloseAtEnd", False);
	Result.Insert("ThereAreStageRecordingErrors", False);
	Result.Insert("ThereAreErrorsInRecordingTechnicalProcess", False);
	Result.Insert("BriefErrorDescription", "");
	Result.Insert("DetailErrorDescription", "");
	Result.Insert("ErrorText", "");
	Result.Insert("ErrorTextLR", "");
	
	Return Result;
	
EndFunction

Function ResultOfCreatingTypicalTechnicalProcessConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("HasErrors", False);
	Result.Insert("TechnologicalProcess");
	
	Return Result;
	
EndFunction

#Region UpdateStageData

// The "Add" action.
// 
// Returns:
//  String
Function ActionAdd() Export
	Return NStr("vi = 'Thêm';
				|ru = 'Добавить';
				|en = 'Add'; fa = 'افزودن';
				|it = 'Add';
				|pl = 'Add';
				|tr = 'Ekle'");
EndFunction

// The "Delete" action.
// 
// Returns:
//  String
Function ActionDelete() Export
	Return NStr("vi = 'Xóa';
				|ru = 'Удалить';
				|en = 'Delete'; fa = 'حذف';
				|it = 'Eliminare';
				|pl = 'Delete';
				|tr = 'Sil'");
EndFunction

// The "Zoom in" action.
// 
// Returns:
//  String
Function ZoomInAction() Export
	Return NStr("vi = 'Tăng';
				|ru = 'Увеличить';
				|en = 'Increase'; fa = 'افزایش';
				|it = 'Increase';
				|pl = 'Increase';
				|tr = 'Artır'");
EndFunction

// The "Reduce" action.
// 
// Returns:
//  String
Function ReduceAction() Export
	Return NStr("vi = 'Giảm';
				|ru = 'Уменьшить';
				|en = 'Decrease'; fa = 'کاهش';
				|it = 'Decrease';
				|pl = 'Decrease';
				|tr = 'Azalt'");
EndFunction

Function CommentMatches()
	Return NStr("vi = 'Trùng với công đoạn';
				|ru = 'Совпадает с этапом';
				|en = 'Matches the stage'; fa = 'Matches the stage';
				|it = 'Matches the stage';
				|pl = 'Matches the stage';
				|tr = 'Aşama ile eşleşiyor'");
EndFunction

Function CommentCannotBeReduced()
	Return NStr("vi = 'Không thể giảm';
				|ru = 'Нельзя уменьшить';
				|en = 'Cannot reduce'; fa = 'کاهش امکان‌پذیر نیست';
				|it = 'Cannot reduce';
				|pl = 'Cannot reduce';
				|tr = 'Azaltılamaz'");
EndFunction

Function CommentCannotBeDeleted()
	Return NStr("vi = 'Không thể xóa';
				|ru = 'Нельзя удалить';
				|en = 'Cannot delete'; fa = 'Cannot delete';
				|it = 'Cannot delete';
				|pl = 'Cannot delete';
				|tr = 'Silinemez'");
EndFunction

// Array of actions for changing existing stage lines
// 
// Returns:
//  ValueList of String
Function ActionsChangeExistingOnes() Export
	
	Result = New ValueList();
	
	Result.Add(ZoomInAction());
	Result.Add(ReduceAction());
	Result.Add(ActionDelete());
	
	Return Result;
	
EndFunction

// A list of security options, the lines of the stage with which are not changed by the editor 
// 
// Returns:
//  Array of EnumRef.SupplyOptions
Function OptionsForSupplyingStageLinesAreNonEditable() Export
	
	Result = New Array;
	
	Result.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
	Result.Add(PredefinedValue("Enum.SupplyOptions.TransferedEarlier"));
	Result.Add(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
	Result.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
	
	Return Result;
	
EndFunction

// Determines whether the stage line can be changed.
// 
// Parameters:
//  TSName - String
//  RowData - FormDataStructure
//  Action - String
// 
// Returns:
//  Boolean
Function YouCanChangeStageString(TSName, RowData, Action) Export
	
	SupplyOptions = OptionsForSupplyingStageLinesAreNonEditable();
	EmptyUID = CommonClientServer.BlankUUID();
	
	Cancel = (TSName = "ManufacturedProducts" And Action = ZoomInAction()
						And (RowData.Manufactured Or RowData.Canceled))
		Or (TSName = "ManufacturedProducts" And Action = ReduceAction()
						And RowData.Manufactured)
		Or (TSName = "SideAndIntermediateRelease" And Action = ZoomInAction()
						And (RowData.Manufactured Or RowData.Canceled))
		Or (TSName = "SideAndIntermediateRelease" And Action = ReduceAction()
						And RowData.Manufactured)
		Or (TSName = "SupplyWithMaterialsAndWorks" And Action = ZoomInAction()
						And (RowData.CommunicationKeySet <> EmptyUID Or SupplyOptions.Find(RowData.SupplyOption) <> Undefined))
		Or (TSName = "SupplyWithMaterialsAndWorks" And Action = ReduceAction()
						And (RowData.Produced Or SupplyOptions.Find(RowData.SupplyOption) <> Undefined)
		Or (TSName = "LaborCosts" And Action = ZoomInAction()
						And (RowData.Completed2 Or RowData.Canceled))
		Or (TSName = "LaborCosts" And Action = ReduceAction()
						And RowData.Completed2));
	
	Return Not Cancel;
	
EndFunction

// The available amount of resource to increase
// 
// Parameters:
//  RowData - FormDataStructure
// 
// Returns:
// Number
Function CanBeIncreased(RowData) Export
	
	Return RowData.CountStage - RowData.CannotBeIncreased;
	
EndFunction

// Available amount of resource to decrease
// 
// Parameters:
//  RowData - FormDataStructure
// 
// Returns:
// Number
Function CanBeReduced(RowData) Export
	
	Return RowData.CountStage - RowData.CannotBeReduced;
	
EndFunction

// Fills in the default parameters in the action line
// 
// Parameters:
//  RowData - FormDataStructure
//  StageTSName - String - name of the tabular part of the stage
//
Procedure FillInDefaultActionParameters(RowData, StageTSName) Export
	
	If Not RowData.IsChanged Then
		RowData.ReadOnly = True;
		RowData.Comment = CommentMatches();
	ElsIf RowData.NumberOfTechnicalProcesses > RowData.CountStage And CanBeIncreased(RowData) > 0 Then
		RowData.Action = ZoomInAction();
	ElsIf RowData.NumberOfTechnicalProcesses > RowData.CountStage Then
		RowData.Action = ActionAdd();
	ElsIf RowData.NumberOfTechnicalProcesses = 0 Then
		RowData.Action = ActionDelete();
		If RowData.CannotBeReduced > 0 Then
			RowData.ReadOnly = True;
			RowData.Comment = CommentCannotBeDeleted();
		EndIf;
	ElsIf RowData.NumberOfTechnicalProcesses < RowData.CountStage Then
		RowData.Action = ReduceAction();
		If RowData.CountStage - RowData.NumberOfTechnicalProcesses > CanBeReduced(RowData) Then
			RowData.ReadOnly = True;
			RowData.Comment = CommentCannotBeReduced();
		EndIf;
	EndIf;
	
	If RowData.Action <> ActionAdd() Then
		FillPropertyValues(RowData, New Structure("WithAssignment,Warehouse,ProductCostElement"));
	EndIf;
	
	RowData.Mark = DefaultMark(RowData, StageTSName);
	
EndProcedure

// The mark in the default line.
// 
// Parameters:
//  RowData - FormDataStructure
//  StageTSName - String - name of the tabular part of the stage
// 
// Returns:
//  Boolean 
Function DefaultMark(RowData, StageTSName)
	
	Result = False;
	
	If Not RowData.IsChanged
		Or RowData.ReadOnly Then
		Result = False;
	ElsIf StageTSName = "LaborCosts" Then
		Result = True;
	ElsIf StageTSName = "SupplyWithMaterialsAndWorks"
		And (RowData.Action = ActionAdd()
			Or RowData.Action = ZoomInAction()) Then
		Result = True;
	ElsIf StageTSName = "ManufacturedProducts"
		And (RowData.Action = ActionAdd()
			Or (RowData.Action = ZoomInAction())
				And RowData.CostType = PredefinedValue("Enum.CostTypesOfFinishedProducts.Fixed")) Then
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Constants

// Background data recording Operation.
// 
// Returns:
//  String
Function BackgroundDataRecordingOperation() Export
	Return NStr("vi = 'Ghi quy trình công nghệ.';
				|ru = 'Запись технологического процесса.';
				|en = 'Technological process record.'; fa = 'Technological process record.';
				|it = 'Technological process record.';
				|pl = 'Technological process record.';
				|tr = 'Teknolojik süreç kaydı.'");
EndFunction

// The background Operation is the creation of a technical process.
// 
// Returns:
//  String
Function BackgroundOperationCreatingProcess() Export
	Return NStr("vi = 'Tạo quy trình công nghệ.';
				|ru = 'Создание технологического процесса.';
				|en = 'Create a technological process.'; fa = 'Create a technological process.';
				|it = 'Create a technological process.';
				|pl = 'Create a technological process.';
				|tr = 'Teknolojik sürecin oluşturulması.'");
EndFunction

// Mode for opening the process editor from the stage form.
// 
// Returns:
// String
Function ModeFromStageForm() Export
	
	Return "FromDocument";
	
EndFunction

// The mode of opening the process editor from the list of documents.
// 
// Returns:
// String
Function ModeFromList() Export
	
	Return "FromList"
	
EndFunction

#EndRegion

#EndRegion

#EndRegion
