
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
		
	If Partner = Undefined Or Partner.IsEmpty() Then
		 Cancel = True;
		 Return;
	EndIf;

	SelfServiceServer.FillInContactPersonSelectionList(Items.ContactPersonFilter.ChoiceList, Partner, ContactPerson);
	SetParametersForDynamicListRequest();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	DoNotShowReviewed = Settings.Get("DoNotShowReviewed");
	ContactPersonFilter       = Settings.Get("ContactPersonFilter");
	
	ChangeYourContactPerson();
	If DoNotShowReviewed Then
		CommonClientServer.SetDynamicListFilterItem(List, "Status", ListOfClosedClaimStatuses(),
		                                                     DataCompositionComparisonType.NotInList,,True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContactPersonFilterOnChange(Item)
	
	ChangeYourContactPerson();
	
EndProcedure

&AtClient
Procedure DoNotShowReviewedOnChange(Item)
	
	If DoNotShowReviewed Then
		CommonClientServer.SetDynamicListFilterItem(List, "Status", ListOfClosedClaimStatuses(),
		                                                     DataCompositionComparisonType.NotInList,,True);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Status");
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Status <> PredefinedValue("Enum.CustomerComplaintStatuses.Registered1") Then
		Cancel = True;
		SelfServiceClient.PrintCustomerClaim(CurrentData.Ref);
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormControlEventHandlers

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDragCheck(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDrag(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RelatedDocuments(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData <> Undefined Then
		
		OpenForm("CommonForm.RelatedDocuments",New Structure("FilterObject", CurrentData.Ref),ThisForm);
		
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function ListOfClosedClaimStatuses()

	ListOfClosedClaimStatuses = New ValueList;
	ListOfClosedClaimStatuses.Add(PredefinedValue("Enum.CustomerComplaintStatuses.NotFulfilled_"));
	ListOfClosedClaimStatuses.Add(PredefinedValue("Enum.CustomerComplaintStatuses.Fulfilled_"));
	
	Return ListOfClosedClaimStatuses;

EndFunction

&AtServer
Procedure ChangeYourContactPerson()

	If Not ValueIsFilled(ContactPersonFilter) Then
		
		QueryText = "
		|SELECT
		|	CustomerClaims.Description,
		|	CASE
		|		WHEN CustomerClaims.Status = VALUE(Enum.CustomerComplaintStatuses.Registered1)
		|				OR CustomerClaims.Status = VALUE(Enum.CustomerComplaintStatuses.InProcessing)
		|			THEN PRESENTATION(CustomerClaims.Status)
		|		ELSE &Discussed
		|	END AS StatusPresentation,
		|	CustomerClaims.Status,
		|	CustomerClaims.ComplaintDescription,
		|	CustomerClaims.ProcessingResult,
		|	CustomerClaims.RegistrationDate,
		|	CustomerClaims.EndDate,
		|	CustomerClaims.Ref
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	CustomerClaims.Partner = &Partner
		|";
		
	Else
		
		QueryText = "
		|SELECT
		|	CustomerClaims.Description,
		|	CASE
		|		WHEN CustomerClaims.Status = VALUE(Enum.CustomerComplaintStatuses.Registered1)
		|				OR CustomerClaims.Status = VALUE(Enum.CustomerComplaintStatuses.InProcessing)
		|			THEN PRESENTATION(CustomerClaims.Status)
		|		ELSE &Discussed
		|	END AS StatusPresentation,
		|	CustomerClaims.Status,
		|	CustomerClaims.ComplaintDescription,
		|	CustomerClaims.ProcessingResult,
		|	CustomerClaims.RegistrationDate,
		|	CustomerClaims.EndDate,
		|	CustomerClaims.Ref
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	CustomerClaims.Ref IN
		|			(SELECT DISTINCT
		|				CustomerClaims.Ref AS Ref
		|			FROM
		|				Catalog.Complaints.PartnersAndContactPersons AS CustomerClaimsPartnersAndContactPersons
		|					INNER JOIN Catalog.Complaints AS CustomerClaims
		|					ON
		|						CustomerClaimsPartnersAndContactPersons.Ref = CustomerClaims.Ref
		|			WHERE
		|				CustomerClaims.Partner = &Partner
		|				AND CustomerClaimsPartnersAndContactPersons.ContactPerson = &ContactPerson)";
		
	EndIf;
	
	Properties = Common.DynamicListPropertiesStructure();
	Properties.QueryText = QueryText;
	
	Common.SetDynamicListProperties(Items.List, Properties);
	
	SetParametersForDynamicListRequest();

EndProcedure

&AtServer
Procedure SetParametersForDynamicListRequest()

	CommonClientServer.SetDynamicListParameter(List, "Partner", Partner);
	CommonClientServer.SetDynamicListParameter(List, "ContactPerson", ContactPersonFilter);
	CommonClientServer.SetDynamicListParameter(List, "Discussed", NStr("vi = 'Đã xem xét';
																		|ru = 'Рассмотрена';
																		|en = 'Reviewed'; fa = 'بررسی‌شده';
																		|it = 'Presa in esame';
																		|pl = 'Reviewed';
																		|tr = 'İncelendi'"));

EndProcedure


#EndRegion
