#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ObjectAttributesLock.LockAttributes(ThisForm);

	UseSeveralPriceTypes    = GetFunctionalOption("UseSeveralPriceTypes");
	Items.PriceTypesGroup.Visible = UseSeveralPriceTypes;
	
	PopulateTargetLocationSelectionList();
	FillInSelectionListPlacementTechnology();

	UseSeveralPriceTypes = GetFunctionalOption("UseSeveralPriceTypes");
	ItIsAllowedToCreatePriceTypes     = UseSeveralPriceTypes
                                  And AccessRight("Insert", Metadata.Catalogs.TypesOfPrices);
	ItIsAllowedToCreatePriceTypes                       = UseSeveralPriceTypes
	                                                And AccessRight("Insert", Metadata.Catalogs.TypesOfPrices);

	If (Not UseSeveralPriceTypes)
		And (Not ValueIsFilled(Object.RetailPriceType)) Then
		Object.RetailPriceType = PriceManagementSystem.PriceTypePriceList_();
	EndIf;

	// Price Type Settings
	UsePriceManagementSystem25                   = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	RefreshUseRetailPriceViewCheckbox();
	If UseSeveralPriceTypes Then		
		UpdateIndividualPriceViewPresentation();		
		UpdateUseCustomPriceViewCheckbox();
		AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisForm);	
	EndIf;
	// End of Setting Up Price types


	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// Assembly and delivery
	SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(ThisForm);
	// End Assembly and Delivery
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ObjectAttributesLock.LockAttributes(ThisForm);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.OrdersAssemblyAndCourierDeliverySettings.Form.Settings" Then
		Modified = True;
		FillPropertyValues(Object, ValueSelected);
		SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GoodsPlacementAndCustomerServiceTechnologyOnChange(Item)
	
	FillInSelectionListPlacementTechnology();
	
EndProcedure

&AtClient
Procedure TargetLocationOnChange(Item)
	
	PopulateTargetLocationSelectionList();
	
EndProcedure

&AtClient
Procedure MinimumSellingAreaOnChange(Item)
	If Object.MaximumSellingArea < Object.MinimumSellingArea Then
		If Object.MaximumSellingArea <> 0 Then
			MessageText = NStr("vi = 'Diện tích tối thiểu không thể lớn hơn diện tích tối đa!';
								|ru = 'Минимальная площадь не может быть больше максимальной!';
								|en = 'Minimum area cannot be greater than the maximum area.'; fa = 'Minimum area cannot be greater than the maximum area.';
								|it = 'L''area minima non può essere maggiore di quella massima!';
								|pl = 'Minimalna powierzchnia nie może być większa od maksymalnej!';
								|tr = 'Minimum alan, maksimum alandan daha büyük olamaz!'");
			CommonClientServer.MessageToUser(MessageText);
		EndIf;
		Object.MaximumSellingArea = Object.MinimumSellingArea;
	EndIf;
EndProcedure

&AtClient
Procedure MaximumSellingAreaOnChange(Item)
	If Object.MaximumSellingArea < Object.MinimumSellingArea Then
		MessageText = NStr("vi = 'Diện tích tối đa không thể nhỏ hơn diện tích tối thiểu!';
							|ru = 'Максимальная площадь не может быть меньше минимальной!';
							|en = 'Maximum area cannot be less than the minimum area.'; fa = 'Maximum area cannot be less than the minimum area.';
							|it = 'L''area massima non può essere inferiore a quella minima!';
							|pl = 'Maksymalna powierzchnia nie może być większa od minimalnej!';
							|tr = 'Maksimum alan, minimum alandan daha küçük olamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		Object.MinimumSellingArea = Object.MaximumSellingArea;
	EndIf;	
EndProcedure

&AtClient
Procedure UseIndividualViewOfPriceWhenChangingOnClient()

	If UseAnIndividualViewOfThePrice Then
	
		If Not ValueIsFilled(Object.Ref) Then
			
			Return;
			
		EndIf;

		ShutdownResult = FindIndividualViewOfPrices();
	
	Else
		
		If Object.SpecialPriceType.IsEmpty() Then
			
			Return;
			
		EndIf;
		
//		Display the user's notification ("Disabling the individual type of price", , , , the status of the user's notification.Information );
		
		ShutdownResult = DisableIndividualPriceViewServer();
		
		If Not ShutdownResult.Result Then
			
			UseAnIndividualViewOfThePrice = True;
			
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Đã xảy ra lỗi khi ngắt bảng giá riêng';
					|ru = 'Возникла ошибка при отключении индивидуального прайс листа';
					|en = 'An error occurred while disabling the individual price list'; fa = 'An error occurred while disabling the individual price list';
					|it = 'Si è verificato un errore durante la disabilitazione del listino prezzi individuale';
					|pl = 'Wystąpił błąd podczas wyłączenia indywidualnego cennika';
					|tr = 'Özelleştirilmiş fiyat listesi devre dışı bırakılırken hata oluştu'") + " " + ShutdownResult.ErrorDescription,
				Object.Ref,
				);
			
		EndIf;
		
	EndIf;
		
EndProcedure

&AtServer
Function DisableIndividualPriceViewServer()
	
	ShutdownResult = Catalogs.TypesOfPrices.DisableIndividualPriceView(Object.SpecialPriceType);

	If ShutdownResult.Result Then
		
		Object.SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
		UpdateIndividualPriceViewPresentation();
		
	EndIf;
		
	Return ShutdownResult;
	
EndFunction

&AtServer
Function FindIndividualViewOfPrices()
	
	SearchResult = Catalogs.TypesOfPrices.FindIndividualViewOfPrices(Object.Ref);
	
	If SearchResult.Result Then
		Object.SpecialPriceType = SearchResult.Ref;
		UpdateIndividualPriceViewPresentation();
	EndIf;
			
	Return SearchResult;
	
EndFunction

&AtClient
Procedure UseAnIndividualViewOfThePriceOnChange(Item)
	
	UseIndividualViewOfPriceWhenChangingOnClient();
	AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisForm);
	
EndProcedure

&AtClient
Function HyperlinkClickParameters(TagName, Hyperlink = "")

	If TagName = "HyperlinkGoToPriceList" Then
		
		TypesOfPrices = New Array();
		TypesOfPrices.Add(Object.RetailPriceType);
		TypesOfPrices.Add(Object.SpecialPriceType);
		
		FormParameters = New Structure;
		FormParameters.Insert("TypesOfPrices",  TypesOfPrices);
		
		HyperlinkClickParameters = New Structure;
		HyperlinkClickParameters.Insert("FormName", "DataProcessor.PriceList.Form.Form");
		HyperlinkClickParameters.Insert("FormParameters",FormParameters);
		
	ElsIf TagName = "HyperlinkGoPriceChangeHistory" Then
		
		TypesOfPrices = New Array();
		TypesOfPrices.Add(Object.RetailPriceType);
		TypesOfPrices.Add(Object.SpecialPriceType);
		
		FormParameters = New Structure;
		FormParameters.Insert("TypesOfPrices",  TypesOfPrices);
		
		HyperlinkClickParameters = New Structure;
		If UsePriceManagementSystem25 Then
			HyperlinkClickParameters.Insert("FormName", "InformationRegister.ItemsPrices25.Form.ListForm");
		Else	
			HyperlinkClickParameters.Insert("FormName", "InformationRegister.ItemsPrices.Form.ListForm");
		EndIf;
		HyperlinkClickParameters.Insert("FormParameters", FormParameters);
			
	EndIf;
	
	If Not HyperlinkClickParameters.Property("FormWindowOpeningMode") Then
		HyperlinkClickParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.Independent);
	EndIf;
	HyperlinkClickParameters.Insert("TagName", TagName);
	HyperlinkClickParameters.Insert("Hyperlink", Hyperlink);
	
	Return HyperlinkClickParameters
EndFunction

&AtClient
Procedure HyperlinkGoToPriceListURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	HyperlinkClickParameters = HyperlinkClickParameters(Item.Name);
	HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoPriceChangeHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	HyperlinkClickParameters = HyperlinkClickParameters(Item.Name);
	HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến thông tin bổ sung sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Переход к дополнительной информации возможен только после записи элемента.
		|Записать элемент?';
		|en = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?'; fa = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?';
		|it = 'I dati non sono ancora stati registrati.
		|Il passaggio all''informazione aggiuntiva è possibile solo dopo la registrazione dell''elemento.
		|Registrare l''elemento?';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do informacji dodatkowej jest możliwe tylko po zapisaniu elementu.
		|Zapisać element?';
		|tr = 'Veriler henüz kaydedilmedi.
		|Ek bilgilere geçiş sadece öğenin kaydından sonra mümkündür.
		|Öğe kaydedilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("HyperlinkGoQuestionCompletion", ThisObject, HyperlinkClickParameters), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	GoHyperlink(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoQuestionCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	HyperlinkClickParameters = HyperlinkClickParameters(AdditionalParameters.TagName,
																		AdditionalParameters.Hyperlink);
	GoHyperlink(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure GoHyperlink(HyperlinkClickParameters)
	
	If HyperlinkClickParameters.Property("FormName") Then
		OpenForm(HyperlinkClickParameters.FormName,
			HyperlinkClickParameters.FormParameters, , ThisForm.UUID, , , ,
			HyperlinkClickParameters.FormWindowOpeningMode);
	Else
		ExceptionText = NStr("vi = 'Chưa xác định thao tác theo hyperlink.';
							|ru = 'Не определено действие по гиперссылке.';
							|en = 'Hyperlink action is not identified.'; fa = 'Hyperlink action is not identified.';
							|it = 'Azione ipertestuale non definita.';
							|pl = 'Nie określono działania hiperłącza.';
							|tr = 'Köprü eylemi tanımlanmadı.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// AssemblyAndDelivery
&AtClient
Procedure SetUpOrderCollectionAndCourierDelivery(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("StoreSupportsOrderAssembly", Object.StoreSupportsOrderAssembly);
	FormParameters.Insert("StoreSupportsDeliveryByOwnCouriers", Object.StoreSupportsDeliveryByOwnCouriers);
	FormParameters.Insert("MethodOfSalesCreatingWhenAssemblingOrders", Object.MethodOfSalesCreatingWhenAssemblingOrders);
	FormParameters.Insert("MethodOfFiscalizationUponDelivery", Object.MethodOfFiscalizationUponDelivery);
	FormParameters.Insert("AssemblyAndDeliveryIsDoneBySameEmployee", Object.AssemblyAndDeliveryIsDoneBySameEmployee);
	FormParameters.Insert("CouriersCanAssignOrdersToThemselves", Object.CouriersCanAssignOrdersToThemselves);
	FormParameters.Insert("PickersCanAssignJobsToThemselves", Object.PickersCanAssignJobsToThemselves);
	FormParameters.Insert("StandardOrderDeliveryTime", Object.StandardOrderDeliveryTime);
	FormParameters.Insert("CouriersUsePOSTerminals", Object.CouriersUsePOSTerminals);
	FormParameters.Insert("CouriersUseAutonomousCREs", Object.CouriersUseAutonomousCREs);
	FormParameters.Insert("FormMode", 1);
	FormParameters.Insert("Object", Object);
	FormParameters.Insert("GroupingOfGoods", Object.GroupingOfGoods);
	
	OpenForm("DataProcessor.OrdersAssemblyAndCourierDeliverySettings.Form.Settings", FormParameters, ThisForm);
		
EndProcedure
// End AssemblyAndDelivery

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		
		OpenForm("Catalog.StoreFormats.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
		AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisForm);
			
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure PopulateTargetLocationSelectionList()
	Items.TargetLocation.ChoiceList.Clear();
	OptionsArray = GetOptions("StoreFormats", "TargetLocation", "IsFolder");
	
	For Each Variant In OptionsArray Do
		Items.TargetLocation.ChoiceList.Add(Variant);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInSelectionListPlacementTechnology()
	Items.GoodsPlacementAndCustomerServiceTechnology.ChoiceList.Clear();
	OptionsArray = GetOptions("StoreFormats", "GoodsPlacementAndCustomerServiceTechnology", "IsFolder");
	
	For Each Variant In OptionsArray Do
		Items.GoodsPlacementAndCustomerServiceTechnology.ChoiceList.Add(Variant);
	EndDo;
	
EndProcedure

// The function generates a request to get all the texts entered earlier in the specified field
//
// Parameters:
//	TableName - String - a string containing the name of the table from which the selection is performed
//	Var_AttributeName - String - name of the Attribute whose values you want to get
//	GroupConditionString - String - path to the value of the "this group" Attribute 
//							to exclude groups from being included in the query result
// Return value 
//	An array of options is an array containing text values.
&AtServer
Function GetOptions(TableName, Var_AttributeName, GroupConditionString)
	Query = New Query("SELECT
	                      |	Table."+Var_AttributeName+" AS VariantValue
	                      |FROM
	                      |	Catalog."+TableName+" AS Table
						  |WHERE
						  |	(NOT Table."+GroupConditionString+")
						  |	AND Table."+Var_AttributeName+"<>""""
	                      |GROUP BY
	                      |	Table."+Var_AttributeName+"
	                      |ORDER BY
	                      |	VariantValue
						  |");
	QueryResult=Query.Execute();
	OptionsArray = QueryResult.Unload().UnloadColumn("VariantValue");
	If ValueIsFilled(Object[Var_AttributeName]) Then
		If OptionsArray.Find(Object[Var_AttributeName]) = Undefined Then
			OptionsArray.Add(Object[Var_AttributeName]);
		EndIf;
	EndIf;
	
	Return OptionsArray;
EndFunction

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// End StandardSubsystems.Properties


// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);

EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

// Assembly and delivery
&AtClientAtServerNoContext
Procedure SetTitleOfOrderAssemblyAndCourierDeliverySettingsElements(Form)
	
	TitleText = NStr("vi = 'Tùy chỉnh đóng gói đơn hàng và giao hàng bởi bộ phận giao hàng của doanh nghiệp';
					|ru = 'Настроить сборку заказов и доставку своими курьерами';
					|en = 'Configure order picking and delivery by in-house couriers'; fa = 'پیکربندی جمع‌آوری سفارش و تحویل توسط پیک‌های داخلی';
					|it = 'Impostare assemblaggio ordini e consegna per corrieri propri';
					|pl = 'Skonfiguruj kompletację zamówień i dostawę przez swoich kurierów';
					|tr = 'Sipariş alımını ve kendi kurye teslimatınızı ayarlayın'");
	Object = Form.Object;
	
	If Object.StoreSupportsOrderAssembly
		Or Object.StoreSupportsDeliveryByOwnCouriers Then
		TitleText = NStr("vi = 'Thay đổi tùy chỉnh đóng bộ đơn hàng và giao hàng bởi bộ phận giao hàng của doanh nghiệp';
						|ru = 'Изменить настройки сборки заказов и доставки своими курьерами';
						|en = 'Edit settings for order picking and delivery by own couriers'; fa = 'Edit settings for order picking and delivery by own couriers';
						|it = 'Modificare le impostazioni di assemblaggio degli ordini e di consegna tramite propri corrieri';
						|pl = 'Zmień ustawienia kompletacji zamówień i dostawy przez swoich kurierów';
						|tr = 'Kendi kuryeleriniz tarafından sipariş alımı ve teslimat ayarlarını değiştirin'");
	EndIf;
	
	Form.Items.SetUpOrderCollectionAndCourierDelivery.Title = TitleText;
		
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure RefreshUseRetailPriceViewCheckbox()

	UseTheRetailPriceView = True;
	
EndProcedure

&AtServer
Procedure UpdateUseCustomPriceViewCheckbox()

	UseAnIndividualViewOfThePrice = ValueIsFilled(Object.SpecialPriceType);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(Form)
	
	Form.Items.SpecialPriceTypePresentation.Enabled	= (Form.UseAnIndividualViewOfThePrice 
												And Not Form.Items.UseAnIndividualViewOfThePrice.ReadOnly)
												And Form.ItIsAllowedToCreatePriceTypes;
	Form.Items.UseAnIndividualViewOfThePrice.Enabled = Form.ItIsAllowedToCreatePriceTypes;
	
EndProcedure

&AtServer
Procedure UpdateIndividualPriceViewPresentation()
	If ValueIsFilled(Object.SpecialPriceType) Then
		ArrayOfTexts = New Array;

		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'Dạng giá riêng';
													|ru = 'Индивидуальный вид цен';
													|en = 'Special price type'; fa = 'نوع قیمت ویژه';
													|it = 'Tipo di prezzo individuale';
													|pl = 'Indywidualny rodzaj cen';
													|tr = 'Özelleştirilmiş fiyat türü'")));
		
		ArrayOfTexts.Add(" (");
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'tùy chỉnh';
													|ru = 'настроить';
													|en = 'configure'; fa = 'configure';
													|it = 'impostare';
													|pl = 'configure';
													|tr = 'ayarla'"),,,,"OpenIVC"));
		ArrayOfTexts.Add(")");
		
	Else
		ArrayOfTexts = New Array;
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'Dạng giá riêng (chưa tùy chỉnh)';
													|ru = 'Индивидуальный вид цен (не настроен)';
													|en = 'Special price type (not configured)'; fa = 'Special price type (not configured)';
													|it = 'Tipo di prezzo individuale (non impostato)';
													|pl = 'Indywidualny rodzaj cen (nie ustawiono)';
													|tr = 'Özelleştirilmiş fiyat türü (ayarlanmadı)'")));

		ArrayOfTexts.Add(" (");
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'tùy chỉnh';
													|ru = 'настроить';
													|en = 'configure'; fa = 'configure';
													|it = 'impostare';
													|pl = 'configure';
													|tr = 'ayarla'"),,,,"CreateIVC"));
		ArrayOfTexts.Add(")");
	EndIf;
	
	SpecialPriceTypePresentation = New FormattedString(ArrayOfTexts);
EndProcedure

&AtClient
Procedure SpecialPriceTypePresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "CreateIVC" Then

		If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
			QueryText = NStr("vi = 'Dữ liệu đã chỉnh sửa.
			|Chỉ có thể tùy chỉnh bảng giá riêng sau khi ghi lại phần tử.
			|Ghi lại phần tử?';
			|ru = 'Данные модифицированы.
			|Настройка индивидуального прайс-листа возможна только после записи элемента.
			|Записать элемент?';
			|en = 'The data has been modified.
			|Configuring an individual price list is only available after saving element.
			|Save the item?'; fa = 'The data has been modified.
			|Configuring an individual price list is only available after saving element.
			|Save the item?';
			|it = 'Dati modificati. 
			|L''impostazione del listino prezzi individuale è possibile solamente dopo la registrazione dell''elemento. 
			|Registrare elemento?';
			|pl = 'Dane zostały zmodyfikowane.
			|Ustawienie indywidualnego cennika jest możliwe tylko po zapisywaniu elementu.
			|Zapisać element?';
			|tr = 'Veriler değiştirildi.
			|Özelleştirilmiş fiyat listesi ayarı sadece öğenin kaydından sonra mümkündür.
			|Öğe kaydedilsin mi?'");
			
			ShowQueryBox(New CallbackDescription("CreateIVCQuestionCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
	
		CreateIVCCompletion();
		
	ElsIf FormattedStringURL = "OpenIVC" Then
			 	
		ShowValue(Undefined, Object.SpecialPriceType);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateIVCQuestionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	CreateIVCCompletion();
	
EndProcedure

&AtClient
Procedure CreateIVCCompletion()
	
//	Display the user's notification("Creating an individual view of the price", , , , the status of the user's notification.Information );
	TransferResult = CreateIPLServer();
	
	If TransferResult.Result Then
		
		Read();
		UpdateIndividualPriceViewPresentation();
		ShowValue(Undefined, Object.SpecialPriceType);
		
	Else
		
		ClearMessages();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Đã xảy ra lỗi khi tạo bảng giá riêng';
				|ru = 'Возникла ошибка при создании индивидуального прайс листа';
				|en = 'An error occurred while generating the individual price list'; fa = 'An error occurred while generating the individual price list';
				|it = 'Возникла ошибка при создании индивидуального прайс листа';
				|pl = 'An error occurred while generating the individual price list';
				|tr = 'Özelleştirilmiş fiyat listesi oluşturulurken hata oluştu'") + " " + TransferResult.ErrorDescription,
			Object.Ref,
			);
			
	EndIf;
	
EndProcedure

&AtServer
Function CreateIPLServer()
	
	TransferResult = SettingPricesServer.CreateIPL(Object.Ref, CurrentSessionDate());
	
	Return TransferResult;
	
EndFunction
// End Assembly and Delivery

#EndRegion
