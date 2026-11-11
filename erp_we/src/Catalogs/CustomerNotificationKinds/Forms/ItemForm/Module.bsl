#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
	EndIf;
	
	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ItIsRequiredToSetUpScheduledJob Then
		CurrentObject.AdditionalProperties.Insert("Schedule", Schedule);
		CurrentObject.AdditionalProperties.Insert("Use", ScheduledJobUsed);
	Else
		If Object.ScheduledJob <> Undefined Then
			CurrentObject.AdditionalProperties.Insert("RemovalScheduledJob", True);
		EndIf;
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupOfMailoutsAndNotificationsOnChange(Item)
	
	GroupOfMailingsAndNotificationsWhenChangesOccurOnServer();
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure EventTypeOnChange(Item)
	
	TypeOfEventWhenChangingOnServer(True);
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure SendingConditionsAreUsedOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure DesignedForEmailsOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure DesignedForSMSMessageOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUpSchedule(Command)
	
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	ScheduleDialog1.Show(New CallbackDescription("SetUpScheduleCompletion", ThisObject, New Structure("ScheduleDialog1", ScheduleDialog1)));
	
EndProcedure

&AtClient
Procedure SetUpScheduleCompletion(Schedule1, AdditionalParameters) Export
	
	ScheduleDialog1 = AdditionalParameters.ScheduleDialog1;
	
	If Schedule1 <> Undefined Then
		
		Modified = True;
		Schedule         = ScheduleDialog1.Schedule;
		If DataSeparationEnabled 
			And Schedule.RepeatPeriodInDay > 0
			And Schedule.RepeatPeriodInDay < 3600 Then
			
			Schedule.RepeatPeriodInDay = 3600;
			
		EndIf;
		ScheduleAsString  = String(Schedule);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeFormula(Command)
	
	If Not DataForFormulaCalculationIsInitialized Then
		BuildTreeOfOperators();
		DataForFormulaCalculationIsInitialized = True;
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("OperandsTree", OperandTreeOfFormulaConstructor());
	
	FormParameters.Insert("Formula", Object.SendingCondition);
	FormParameters.Insert("Operators", OperatorsTreeStorageAddress);
	FormParameters.Insert("ResultType", New TypeDescription("Boolean"));
	
	CallbackDescription = New CallbackDescription("AfterOpeningConstructorSetConditionFormula",ThisObject);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.FormulasConstructor", FormParameters, ThisForm,,,,CallbackDescription,Mode);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function OperandTreeOfFormulaConstructor()
	
	Tree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	TypeOfAlertEvents = Object.EventType;
	DCSTemplate = Enums.NotificationEventTypes.GetTemplate(
		TypeOfAlertEvents.Metadata().EnumValues.Get(Enums.NotificationEventTypes.IndexOf(TypeOfAlertEvents)).Name);
	
	AdditionalRestrictions = ProcessingOfFormulas.LimitationsOfOperandSweep();
	AdditionalRestrictions.RecursivelyExpandLayoutSchemeOperands = False;
	
	ItemsTypes = ProcessingOfFormulas.TypesOfOperandTreeElements();
	
	LinesGroup = ProcessingOfFormulas.NewLineOfOperandTree(Tree);
	LinesGroup.Id = "PreviousMessage";
	LinesGroup.Presentation = NStr("vi = 'Tin nhắn trước';
									|ru = 'Предыдущее сообщение';
									|en = 'Previous message'; fa = 'پیام قبلی';
									|it = 'Messaggio precedente';
									|pl = 'Poprzednia wiadomość';
									|tr = 'Önceki mesaj'");
	LinesGroup.TreeItemType = ItemsTypes.TopLevelRowGroup;
	LinesGroup.OperandSelectionAllowed = False;
	LinesGroup.IncludedInID = True;
	
	ProcessingOfFormulas.AddAvailableFieldsToTreeUsingLayoutScheme(LinesGroup, DCSTemplate, AdditionalRestrictions);
	
	
	LinesGroup = ProcessingOfFormulas.NewLineOfOperandTree(Tree);
	LinesGroup.Id = "CurMessage";
	LinesGroup.Presentation = NStr("vi = 'Thông báo hiện tại';
									|ru = 'Текущее сообщение';
									|en = 'Current message'; fa = 'Current message';
									|it = 'Messaggio corrente';
									|pl = 'Bieżąca wiadomość';
									|tr = 'Mevcut mesaj'");
	LinesGroup.TreeItemType = ItemsTypes.TopLevelRowGroup;
	LinesGroup.OperandSelectionAllowed = False;
	LinesGroup.IncludedInID = True;
	
	ProcessingOfFormulas.AddAvailableFieldsToTreeUsingLayoutScheme(LinesGroup, DCSTemplate, AdditionalRestrictions);
	
	
	StorageAddress = PutToTempStorage(Tree, UUID);
	Return StorageAddress;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	FillEventSelectionList();
	GroupOfMailingsAndNotificationsWhenChangesOccurOnServer(True);
	TypeOfEventWhenChangingOnServer(False);
	SegmentsServer.GetScheduleForRoutineTask(ThisForm);
	
	AvailabilityControl(ThisForm);
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	UseOtherInteractions       = GetFunctionalOption("UseOtherInteractions");
	Items.DesignedForSMSMessage.Visible = UseOtherInteractions;
	Items.SMSMessageTemplate.Visible  = UseOtherInteractions;
	
	If Not AccessRight("Read", Metadata.Catalogs.MessageTemplates) Then
		
		Items.AssignmentPages.CurrentPage = Items.PageNoRightsToTemplates;
		ReadOnly = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	Form.Items.SendingConditionsAreUsed.Enabled = ValueIsFilled(Form.Object.EventType);
	Form.Items.SchedulePage.Enabled          = Form.ItIsRequiredToSetUpScheduledJob;
	Form.Items.SendingCondition.Enabled             = Form.Object.SendingConditionsAreUsed;
	Form.Items.ChangeFormula.Enabled             = Form.Object.SendingConditionsAreUsed;
	
	AvailabilityOfMailElements = Form.SendingByEmailIsAvailable Or Form.Object.DesignedForEmails;
	AvailabilityOfSMSElements   = Form.SMSMessagesAreAvailable   Or Form.Object.DesignedForSMSMessage;
	
	Form.Items.DesignedForEmails.Enabled = AvailabilityOfMailElements;
	Form.Items.EmailTemplate.Enabled         = AvailabilityOfMailElements 
	                                                              And Form.Object.DesignedForEmails;
	
	Form.Items.DesignedForSMSMessage.Enabled = AvailabilityOfSMSElements;
	Form.Items.SMSMessageTemplate.Enabled  = AvailabilityOfSMSElements
	                                                 And Form.Object.DesignedForSMSMessage;

EndProcedure

&AtServer
Procedure GroupOfMailingsAndNotificationsWhenChangesOccurOnServer(ReadingExistingOne = False)
	
	If ValueIsFilled(Object.GroupOfMailoutsAndNotifications) Then
		GroupDetails_ = Common.ObjectAttributesValues(Object.GroupOfMailoutsAndNotifications, "DesignedForEmails, DesignedForSMSMessage");
		SendingByEmailIsAvailable = GroupDetails_.DesignedForEmails;
		SMSMessagesAreAvailable   = GroupDetails_.DesignedForSMSMessage;
	Else
		SendingByEmailIsAvailable = False;
		SMSMessagesAreAvailable   = False;
	EndIf;
	
	If Object.Ref.IsEmpty() Or Not ReadingExistingOne  Then 
		If SMSMessagesAreAvailable And Not SendingByEmailIsAvailable Then
			Object.DesignedForSMSMessage = True;
			Object.DesignedForEmails = False;
		ElsIf SendingByEmailIsAvailable And Not SMSMessagesAreAvailable Then
			Object.DesignedForSMSMessage = False;
			Object.DesignedForEmails = True;
		EndIf;
	EndIf;

	
EndProcedure

&AtServer
Procedure TypeOfEventWhenChangingOnServer(CheckEventTypeChanges)
	
	PreviousFullNameOfEventType = FullNameOfTheEventType;
	
	ItIsRequiredToSetUpScheduledJob = Enums.NotificationEventTypes.SettingUpRoutineTaskIsRequired(Object.EventType);
	If ValueIsFilled(Object.EventType) Then
		EnumerationMetadata = Object.EventType.Metadata();
		FullNameOfTheEventType = EnumerationMetadata.EnumValues.Get(Enums.NotificationEventTypes.IndexOf(Object.EventType)).Name;
	Else
		FullNameOfTheEventType = "";
	EndIf;
	
	If CheckEventTypeChanges And PreviousFullNameOfEventType <> FullNameOfTheEventType Then
		Object.SMSMessageTemplate = Catalogs.MessageTemplates.EmptyRef();
		Object.EmailTemplate = Catalogs.MessageTemplates.EmptyRef();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterOpeningConstructorSetConditionFormula(Result, AdditionalParameters) Export

	If Result <> Object.SendingCondition Then
		Object.SendingCondition = Result;
		Modified = True;
	EndIf;

EndProcedure

&AtServer
Procedure BuildTreeOfOperators()
	
	OperatorParameters = New Structure;
	OperatorParameters.Insert("StandardOperators", True);
	OperatorParameters.Insert("BooleanOperators", True);
	OperatorParameters.Insert("Functions", True);
	
	OperatorsTreeStorageAddress = ProcessingOfFormulas.BuildTreeOfOperators(OperatorParameters, UUID);
	
EndProcedure

&AtServer
Procedure FillEventSelectionList()

	For Each EnumerationValue In Enums.NotificationEventTypes.OrderStatusChange.Metadata().EnumValues Do
		
		If Object.EventType <> Enums.NotificationEventTypes[EnumerationValue.Name] Then
			If Not Enums.NotificationEventTypes.DataForProcessingAlertQueue(Enums.NotificationEventTypes[EnumerationValue.Name]).AvailableForUse Then
				Continue;
			EndIf;
		EndIf;
			
		Items.EventType.ChoiceList.Add(Enums.NotificationEventTypes[EnumerationValue.Name],EnumerationValue.Synonym);
		
	EndDo;

EndProcedure

#EndRegion

