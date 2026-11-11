#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
	
		SetVisibility1();
	
	EndIf; 
	
	PricingOfTypeOfWork = Number(Object.RateAccordingToPayScale);
	UnitOfPricing = Number(Object.RatePerHourWorked);
	
	Items.UnitOfPricing.ChoiceList[0].Presentation = ?(ValueIsFilled(Object.UnitOfMeasure),
																		String(Object.UnitOfMeasure),
																		NStr("vi = '<chưa được đặt>';
																			|ru = '<не задана>';
																			|en = '<not set>'; fa = '<تنظیم نشده>';
																			|it = '<non impostato>';
																			|pl = '<nie ustalona>';
																			|tr = '<ayarlanmadı>'"));
	
	Items.JobTitle.AutoMarkIncomplete = PricingOfTypeOfWork = 1;
	
	If UnitOfMeasurementIsHour Then
		UnitOfPricing = 1;
	EndIf;
	
	Object.RatePerHourWorked = Boolean(UnitOfPricing);
	
	ConfigureNavigationBar();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvailability();
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	SetVisibility1();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.RateAccordingToPayScale And Not ValueIsFilled(Object.JobTitle) Then
		Common.MessageToUser(NStr("vi = 'Chưa điền trường ""Chức vụ""';
									|ru = 'Поле ""Должность"" не заполнено';
									|en = '""Job title"" is required'; fa = '""Job title"" is required';
									|it = '""Job title"" is required';
									|pl = '""Job title"" is required';
									|tr = '""Unvan"" alanı doldurulmadı'"), Object.Ref, "Object.JobTitle", , Cancel);
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	
	UnitOfMeasurementWhenChangedOnServer();
	
	SetAvailability();
	
	Items.UnitOfPricing.ChoiceList[0].Presentation = ?(ValueIsFilled(Object.UnitOfMeasure),
																		String(Object.UnitOfMeasure),
																		NStr("vi = '<chưa được đặt>';
																			|ru = '<не задана>';
																			|en = '<not set>'; fa = '<تنظیم نشده>';
																			|it = '<non impostato>';
																			|pl = '<nie ustalona>';
																			|tr = '<ayarlanmadı>'"));
	
	If UnitOfMeasurementIsHour Then
		UnitOfPricing = 1;
	EndIf;
	
	Object.RatePerHourWorked = Boolean(UnitOfPricing);
	
EndProcedure

&AtClient
Procedure PricingOfTypeOfWorkOnChange(Item)
	
	Object.RateAccordingToPayScale = Boolean(PricingOfTypeOfWork);
	
	Items.JobTitle.AutoMarkIncomplete = Object.RateAccordingToPayScale;
	
	If Object.RateAccordingToPayScale Then
		UnitOfPricing = 1;
		Object.RatePerHourWorked = True;
	Else
		Items.JobTitle.MarkIncomplete = False;
	EndIf;
	
	SetAvailability();
	
	ConfigureNavigationBar();
	
EndProcedure

&AtClient
Procedure UnitOfPricingOnChange(Item)
	Object.RatePerHourWorked = Boolean(UnitOfPricing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure SetVisibility1()
	
	LaborIntensityParameters = Catalogs.EmployeeWorkKinds.AutoCompletionParametersForLaborInput(Object);
	Items.GroupLaborIntensity.Visible = Not ValueIsFilled(LaborIntensityParameters);
	
	UnitOfMeasurementIsHour = ValueIsFilled(LaborIntensityParameters)
		And LaborIntensityParameters.LaborInput = 1 And LaborIntensityParameters.LaborInputMultiplier = 1;
	
	RationingAndPricingOfWorksOnTariffGrids = False;
	Items.PricingOfTypeOfWork.Visible = RationingAndPricingOfWorksOnTariffGrids;
	Items.PricingOfTypeOfWork1.Visible = RationingAndPricingOfWorksOnTariffGrids;
	Items.JobTitle.Visible = RationingAndPricingOfWorksOnTariffGrids;
	
EndProcedure

&AtServer
Procedure UnitOfMeasurementWhenChangedOnServer()
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure SetAvailability()
	Items.UnitOfPricing.ReadOnly = UnitOfMeasurementIsHour Or Object.RateAccordingToPayScale;
	Items.UnitOfPricing1.ReadOnly = UnitOfMeasurementIsHour Or Object.RateAccordingToPayScale;
EndProcedure

&AtServer
Procedure ConfigureNavigationBar()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseEmployeeActivityRates", Not Boolean(PricingOfTypeOfWork));
	
	TMCommonUse.ConfigureFormByParameters(ThisObject, SettingsStructure);
	
EndProcedure

#EndRegion
