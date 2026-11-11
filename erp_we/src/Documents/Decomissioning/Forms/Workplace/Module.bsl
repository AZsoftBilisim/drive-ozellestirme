
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If FilterDate.Date = '000101010000' Then
		FilterDate.Variant = StandardBeginningDateVariant.BeginningOfThisDay;
	EndIf;
	
	Items.ListLotStartDateOfOperation.Format = NStr("vi = 'ДФ=''ММММ гггг''';
													|ru = 'ДФ=''ММММ гггг''';
													|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
													|it = 'DF=''MMMM yyyy''';
													|pl = 'DF=''MMMM yyyy''';
													|tr = 'DF=''MMMM yyyy'''");
	Items.ListLotCompletionDate_.Format = NStr("vi = 'ДФ=''ММММ гггг''';
												|ru = 'ДФ=''ММММ гггг''';
												|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
												|it = 'DF=''MMMM yyyy''';
												|pl = 'DF=''MMMM yyyy''';
												|tr = 'DF=''MMMM yyyy'''");
	
	SetListParameters(ThisObject, CurrentSessionDate());
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Decomissioning"
		Or EventName = "Write_OtherGoodsRecordingAsReceived"
		Or EventName = "Write_InventoryConsumptionOrder" Then
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDateOnChange(Item)
	
	If FilterDate.Date = '000101010000' Then
		FilterDate.Variant = StandardBeginningDateVariant.BeginningOfThisDay;
	EndIf;
	
	SetListParameters(ThisObject, CommonClient.SessionDate());

EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetListParameters(ThisObject, CommonClient.SessionDate());

EndProcedure

&AtClient
Procedure FilterFinanciallyLiablePersonOnChange(Item)
	
	SetListParameters(ThisObject, CommonClient.SessionDate());

EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	SetListParameters(ThisObject, CommonClient.SessionDate());

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListProducts Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf Field = Items.ListOperationCategory Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.OperationCategory);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure To_Write_Off(Command)
	
	CreateCharge();

EndProcedure

&AtClient
Procedure ReturnValue_(Command)
	
	CreateRefund();

EndProcedure

&AtClient
Procedure Order(Command)
	
	CreateOrder();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "ListCharacteristic", "List.ItemVariantsAreUsed");
	
	InventoryInOperationServer.SetConditionalRegistrationOfInventoryNumber(
		ThisObject, "ListAssetID", "List.StocktakingRecord", "List.Lot");
	
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(
		ThisObject, "ListIndividual", "List.AccountingForIndividuals", "List.Lot");
		
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer()

	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.ListOrganization.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		Items.ListDepartment.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Items.ListCharacteristic.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseItemsBatch")
		Or Not InventoryInOperationCached.ItIsPossibleToTakeIntoAccountSeriesInOperation() Then
		Items.ListSeries.Visible = False;
	EndIf;
	
	If Not AccessRight("InteractiveInsert", Metadata.Documents.Decomissioning) Then
		Items.ListTo_Write_Off.Visible = False;
	EndIf;
	
	If Not AccessRight("InteractiveInsert", Metadata.Documents.OtherGoodsRecordingAsReceived) Then
		Items.ListReturnValue_.Visible = False;
	EndIf;

	If Not AccessRight("InteractiveInsert", Metadata.Documents.InventoryConsumptionOrder) Then
		Items.ListOrder.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.ListCCDNumber.Visible = False;
		Items.ListQuantityByGBRN.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.8, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() Then
		Items.List.Refresh();
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure SetListParameters(Val Form, Val CurDate)

	List = Form.List; // DynamicList
	
	List.Parameters.SetParameterValue("Period", ?(Form.FilterDate.Date <> '000101010000', EndOfDay(Form.FilterDate.Date), EndOfDay(CurDate)));
	List.Parameters.SetParameterValue("Organization", Form.FilterOrganization);
	List.Parameters.SetParameterValue("Department", Form.FilterDepartment);
	List.Parameters.SetParameterValue("Individual", Form.FilterIndividual);

EndProcedure

&AtClient
Procedure CreateCharge()
	
	ListOfShoppingCenters = New Array;
	
	CurrentCompany = Undefined;
	CurrentDepartment = Undefined;

	For Each RowID In Items.List.SelectedRows Do
		
		RowData = Items.List.RowData(RowID);
		
		If RowData.Organization <> CurrentCompany 
			And CurrentCompany <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn vật tư của một doanh nghiệp';
									|ru = 'Необходимо выбрать ТМЦ одной организации';
									|en = 'Select inventory of one company'; fa = 'Select inventory of one company';
									|it = 'È necessario selezionare i beni materiali di una azienda';
									|pl = 'Należy wybrać zapasy jednej firmy';
									|tr = 'Aynı iş yerinin stoklarının seçilmesi gerekmektedir'"));
			Return;
		EndIf;
		
		If RowData.Department <> CurrentDepartment 
			And CurrentDepartment <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn vật tư của một bộ phận';
									|ru = 'Необходимо выбрать ТМЦ одного подразделения';
									|en = 'Select inventory of one business unit'; fa = 'Select inventory of one business unit';
									|it = 'È necessario selezionare i beni materiali di un reparto';
									|pl = 'Należy wybrać zapasy jednego działu';
									|tr = 'Bir departmanın stokunu seçmek gerekir'"));
			Return;
		EndIf;
		
		PropertiesOfGoodsAndMaterials = New Structure;
		PropertiesOfGoodsAndMaterials.Insert("AssetID", RowData.AssetID);
		PropertiesOfGoodsAndMaterials.Insert("Products", RowData.Products);
		PropertiesOfGoodsAndMaterials.Insert("Characteristic", RowData.Characteristic);
		PropertiesOfGoodsAndMaterials.Insert("Series", RowData.Series);
		PropertiesOfGoodsAndMaterials.Insert("Individual", RowData.Individual);
		PropertiesOfGoodsAndMaterials.Insert("LineOfBusiness", RowData.LineOfBusiness);
		PropertiesOfGoodsAndMaterials.Insert("Lot", RowData.Lot);
		PropertiesOfGoodsAndMaterials.Insert("Count", RowData.Count);
		PropertiesOfGoodsAndMaterials.Insert("CCDNumber", RowData.CCDNumber);
		PropertiesOfGoodsAndMaterials.Insert("QuantityByGBRN", RowData.QuantityByGBRN);
		ListOfShoppingCenters.Add(PropertiesOfGoodsAndMaterials);
		
		CurrentCompany = RowData.Organization;
		CurrentDepartment = RowData.Department;
		
	EndDo;
	
	If ListOfShoppingCenters.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Cần chọn vật tư mà cần lập chứng từ ghi giảm';
								|ru = 'Необходимо выбрать ТМЦ, для которых требуется оформить списание';
								|en = 'Select inventory that requires write-off registration'; fa = 'Select inventory that requires write-off registration';
								|it = 'È necessario selezionare i beni materiali per i quali è necessario formalizzare lo storno';
								|pl = 'Należy wybrać zapasy, dla których należy zarejestrować rozchód';
								|tr = 'Zarar mahsup etmek istediğiniz stoku seçmek gerekir'"));
		Return;
		
	EndIf;
	
	HeaderAttributes = New Structure;
	HeaderAttributes.Insert("Organization", CurrentCompany);
	HeaderAttributes.Insert("Department", CurrentDepartment);

	TheseGrounds = New Structure;
	TheseGrounds.Insert("HeaderAttributes", HeaderAttributes);
	TheseGrounds.Insert("Goods", ListOfShoppingCenters);
	
	FormParameters = New Structure("Basis", TheseGrounds);
	OpenForm("Document.Decomissioning.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure CreateRefund()
	
	ListOfShoppingCenters = New Array;
	
	CurrentCompany = Undefined;
	CurrentDepartment = Undefined;

	For Each RowID In Items.List.SelectedRows Do
		
		RowData = Items.List.RowData(RowID);
		
		If RowData.Organization <> CurrentCompany 
			And CurrentCompany <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn vật tư của một doanh nghiệp';
									|ru = 'Необходимо выбрать ТМЦ одной организации';
									|en = 'Select inventory of one company'; fa = 'Select inventory of one company';
									|it = 'È necessario selezionare i beni materiali di una azienda';
									|pl = 'Należy wybrać zapasy jednej firmy';
									|tr = 'Aynı iş yerinin stoklarının seçilmesi gerekmektedir'"));
			Return;
		EndIf;
		
		If RowData.Department <> CurrentDepartment 
			And CurrentDepartment <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn vật tư của một bộ phận';
									|ru = 'Необходимо выбрать ТМЦ одного подразделения';
									|en = 'Select inventory of one business unit'; fa = 'Select inventory of one business unit';
									|it = 'È necessario selezionare i beni materiali di un reparto';
									|pl = 'Należy wybrać zapasy jednego działu';
									|tr = 'Bir departmanın stokunu seçmek gerekir'"));
			Return;
		EndIf;
		
		PropertiesOfGoodsAndMaterials = New Structure;
		PropertiesOfGoodsAndMaterials.Insert("AssetID", RowData.AssetID);
		PropertiesOfGoodsAndMaterials.Insert("Products", RowData.Products);
		PropertiesOfGoodsAndMaterials.Insert("Characteristic", RowData.Characteristic);
		PropertiesOfGoodsAndMaterials.Insert("Series", RowData.Series);
		PropertiesOfGoodsAndMaterials.Insert("Individual", RowData.Individual);
		PropertiesOfGoodsAndMaterials.Insert("LineOfBusiness", RowData.LineOfBusiness);
		PropertiesOfGoodsAndMaterials.Insert("Lot", RowData.Lot);
		PropertiesOfGoodsAndMaterials.Insert("Count", RowData.Count);
		PropertiesOfGoodsAndMaterials.Insert("NumberOfPackages", RowData.Count);
		PropertiesOfGoodsAndMaterials.Insert("CCDNumber", RowData.CCDNumber);
		PropertiesOfGoodsAndMaterials.Insert("QuantityByGBRN", RowData.QuantityByGBRN);
		ListOfShoppingCenters.Add(PropertiesOfGoodsAndMaterials);
		
		CurrentCompany = RowData.Organization;
		CurrentDepartment = RowData.Department;
		
	EndDo;
	
	If ListOfShoppingCenters.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Cần chọn vật tư mà cần lập chứng từ trả lại';
								|ru = 'Необходимо выбрать ТМЦ, для которых требуется оформить возврат';
								|en = 'Select inventory that requires return registration'; fa = 'Select inventory that requires return registration';
								|it = 'È necessario selezionare i beni materiali per i quali è necessario formalizzare il reso';
								|pl = 'Należy wybrać zapasy, dla których należy zarejestrować zwrot';
								|tr = 'Geri ödeme yapmak istediğiniz mal ve malzemeleri seçmeniz gerekir'"));
		Return;
		
	EndIf;
	
	HeaderAttributes = New Structure;
	HeaderAttributes.Insert("Organization", CurrentCompany);
	HeaderAttributes.Insert("Department", CurrentDepartment);
	HeaderAttributes.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.PutOutOfOperation"));

	TheseGrounds = New Structure;
	TheseGrounds.Insert("HeaderAttributes", HeaderAttributes);
	TheseGrounds.Insert("Goods", ListOfShoppingCenters);
	
	FormParameters = New Structure("Basis", TheseGrounds);
	OpenForm("Document.OtherGoodsRecordingAsReceived.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure CreateOrder()
	
	ListOfShoppingCenters = New Array;
	
	CurrentCompany = Undefined;
	CurrentDepartment = Undefined;
	CurrentDirectionOfActivity = Undefined;
	
	For Each RowID In Items.List.SelectedRows Do
		
		RowData = Items.List.RowData(RowID);
		
		If RowData.Organization <> CurrentCompany 
			And CurrentCompany <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn vật tư của một doanh nghiệp';
									|ru = 'Необходимо выбрать ТМЦ одной организации';
									|en = 'Select inventory of one company'; fa = 'Select inventory of one company';
									|it = 'È necessario selezionare i beni materiali di una azienda';
									|pl = 'Należy wybrać zapasy jednej firmy';
									|tr = 'Aynı iş yerinin stoklarının seçilmesi gerekmektedir'"));
			Return;
		EndIf;
		
		If RowData.Department <> CurrentDepartment 
			And CurrentDepartment <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn vật tư của một bộ phận';
									|ru = 'Необходимо выбрать ТМЦ одного подразделения';
									|en = 'Select inventory of one business unit'; fa = 'Select inventory of one business unit';
									|it = 'È necessario selezionare i beni materiali di un reparto';
									|pl = 'Należy wybrać zapasy jednego działu';
									|tr = 'Bir departmanın stokunu seçmek gerekir'"));
			Return;
		EndIf;
		
		If RowData.LineOfBusiness <> CurrentDirectionOfActivity 
			And CurrentDirectionOfActivity <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn vật tư với một lĩnh vực hoạt động';
									|ru = 'Необходимо выбрать ТМЦ с одним направлением деятельности';
									|en = 'Select inventory with one line of business'; fa = 'Select inventory with one line of business';
									|it = 'È necessario selezionare i beni materiali con un''area di attività';
									|pl = 'Należy wybrać zapasy z jednym rodzajem działalności';
									|tr = 'Bir faaliyet alanına sahip stoku seçilmesi gerekmektedir'"));
			Return;
		EndIf;
		
		PropertiesOfGoodsAndMaterials = New Structure("Products,Characteristic,OperationCategory,Individual,ExpenseItem,Count,NumberOfPackages");
		FillPropertyValues(PropertiesOfGoodsAndMaterials, RowData);
		PropertiesOfGoodsAndMaterials.NumberOfPackages = RowData.Count;
		ListOfShoppingCenters.Add(PropertiesOfGoodsAndMaterials);
		
		CurrentCompany = RowData.Organization;
		CurrentDepartment = RowData.Department;
		CurrentDirectionOfActivity = RowData.LineOfBusiness;
		
	EndDo;
	
	If ListOfShoppingCenters.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Cần chọn vật tư cần lập đơn hàng';
								|ru = 'Необходимо выбрать ТМЦ, для которых требуется оформить заказ';
								|en = 'Select inventory that requires order registration'; fa = 'Select inventory that requires order registration';
								|it = 'È necessario selezionare i beni materiai per i quali è necessario formalizzare l''ordine';
								|pl = 'Należy wybrać zapasy, dla których należy zarejestrować zamówienie';
								|tr = 'Sipariş vermek istediğiniz stoku seçmek gerekir'"));
		Return;
		
	EndIf;
	
	HeaderAttributes = New Structure;
	HeaderAttributes.Insert("Organization", CurrentCompany);
	HeaderAttributes.Insert("Department", CurrentDepartment);
	HeaderAttributes.Insert("LineOfBusiness", CurrentDirectionOfActivity);
	HeaderAttributes.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.TransferToOperation"));

	TheseGrounds = New Structure;
	TheseGrounds.Insert("HeaderAttributes", HeaderAttributes);
	TheseGrounds.Insert("Goods", ListOfShoppingCenters);
	
	FormParameters = New Structure("Basis", TheseGrounds);
	OpenForm("Document.InventoryConsumptionOrder.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion
