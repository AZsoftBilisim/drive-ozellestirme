
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	If CurrentObject.Ref = Catalogs.BudgetingScenarios.ActualData Then
		Items.GroupPages.CurrentPage = Items.ActualData;
	ElsIf CurrentObject.Ref = Catalogs.BudgetingScenarios.BudgetFulfillment Then
		Items.GroupPages.CurrentPage = Items.BudgetFulfillment;
	Else
		Items.GroupPages.CurrentPage = Items.ScheduledData;
	EndIf;

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CourseUseCases(Item)
	
	Object.UseExchangeRatesOfAnotherScenario = RateUsageOption;
	
	If Not Object.UseExchangeRatesOfAnotherScenario Then
		Object.RateScenario = Undefined;
	EndIf;
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

&AtClient
Procedure SetForecastedExchangeRates(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Để cài đặt tỷ giá dự báo, bạn phải ghi lại. Ghi lại?';
						|ru = 'Для настройки прогнозных курсов необходимо записать объект. Записать?';
						|en = 'To configure forecasted exchange rates, save the object. Do you want to save it?'; fa = 'To configure forecasted exchange rates, save the object. Do you want to save it?';
						|it = 'Per impostare i tassi di previsione, è necessario registrare l''oggetto. Registrare?';
						|pl = 'Aby ustawić prognozy kursów, należy zapisać obiekt. Zapisać?';
						|tr = 'Kur tahmin ayarları için nesneyi kaydetmek gerekiyor. Kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("SetForecastedExchangeRatesCompletion", ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	SetForecastFragmentRates();
EndProcedure

&AtClient
Procedure SetForecastedExchangeRatesCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.Yes Then
        Write();
    Else 
        Return
    EndIf;
    
    SetForecastFragmentRates();

EndProcedure

&AtClient
Procedure SetForecastFragmentRates()
    
    FormParameters = New Structure;
    FormParameters.Insert("Scenario", Object.Ref);
    
    OpenForm("InformationRegister.ForecastedExchangeRatesOfScenarios.Form.ListFormForSelectedScenario", 
    FormParameters, 
    ThisObject);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	RateUsageOption = Object.UseExchangeRatesOfAnotherScenario;
	FormControl(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext 
Procedure FormControl(Form)
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items, 
		"SetForecastedExchangeRates", 
		"Enabled", 
		Form.RateUsageOption = 0);
		
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items, 
		"RateScenario", 
		"Enabled", 
		Form.RateUsageOption = 1);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RateScenario.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseExchangeRatesOfAnotherScenario");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

#EndRegion

