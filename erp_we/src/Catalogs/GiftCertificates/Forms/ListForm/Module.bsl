
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CurrentDate = CurrentSessionDate();
	
	If Parameters.Filter.Property("GiftCardAccounting25") Then
		GiftCardAccounting25 = Parameters.Filter.GiftCardAccounting25;
		Parameters.Filter.Delete("GiftCardAccounting25");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"GiftCardAccounting25",
				GiftCardAccounting25,
				DataCompositionComparisonType.Equal,
				,
				,
				DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	ArrayOfUnusedFields = New Array;
	ArrayOfUnusedFields.Add("Status");
	ArrayOfUnusedFields.Add("Balance");
	List.SetRestrictionsForUseInFilter(ArrayOfUnusedFields);
	List.SetRestrictionsForUseInGroup(ArrayOfUnusedFields);
	List.SetRestrictionsForUseInOrder(ArrayOfUnusedFields);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("UpdateFormAttributeValues", 5);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_GiftCertificates"
		Or EventName = "Write_GiftCertificateSale"
		Or EventName = "Write_ReturnOfGiftCards"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Write_BankAccountIssue"
		Or EventName = "Write_PaymentCardTransaction"
		Or EventName = "Write_CashRegisterReceipt"
		Or EventName = "Write_ARAPSettlement" Then
		Items.List.Refresh();
		
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
		
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

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)

	Keys = Rows.GetKeys();
	InformationOnGiftCertificates = GiftCertificatesServerCall.GetGiftCertificatesDetails(Keys);
	
	For Each String In Rows Do
		Data = InformationOnGiftCertificates[String.Key];
		If Data = Undefined Then 
			String.Value.Data["Balance"] = 0;
			String.Value.Data["Status"] = Enums.GiftCertificateStatuses.NotActivated;
		Else
			String.Value.Data["Balance"] = Data.Balance;
			String.Value.Data["Status"] = Data.StatusFromHistoryOfGiftCertificates;
			If Data.InformationAboutTypeOfGiftCertificateIsFilledIn And Data.GiftCardAccounting25 Then
				DataForCalculatingStatus = GiftCertificatesClientServer.DataForCalculatingStatus();
				FillPropertyValues(DataForCalculatingStatus, Data);
				DataForCalculatingStatus.Insert("ActivationStatus", String.Value.Data["ActivationStatus"]);
				String.Value.Data["Status"] = GiftCertificatesClientServer.CalculateStatusOfGiftCertificate2_5(DataForCalculatingStatus);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure ShowAllItems(Command)
	
	ClearSelectionsSetByCommands();
	
EndProcedure

&AtClient
Procedure ShowCurrentOnes(Command)
	
	ClearSelectionsSetByCommands();
	
	NewFilter = CommonClientServer.AddCompositionItem(List.SettingsComposer.Settings.Filter,
			"ActivationStatus",
			DataCompositionComparisonType.Equal,
			True);
	SelectionsSetByTeams.Add(NewFilter);
			
	NewSelectionGroup = CommonClientServer.CreateFilterItemGroup(List.SettingsComposer.Settings.Filter, "FormCommandPanelSelectionsValid", DataCompositionFilterItemsGroupType.AndGroup);
	SelectionsSetByTeams.Add(NewSelectionGroup);
	
	CommonClientServer.AddCompositionItem(NewSelectionGroup,
			"ValidityStartDate",
			DataCompositionComparisonType.LessOrEqual,
			CurrentDate);

	CommonClientServer.AddCompositionItem(NewSelectionGroup,
			"ValidityEndDate",
			DataCompositionComparisonType.GreaterOrEqual,
			CurrentDate);
			
EndProcedure

&AtClient
Procedure ShowNotActivated(Command)
	
	ClearSelectionsSetByCommands();	
	
	NewFilter = CommonClientServer.AddCompositionItem(List.SettingsComposer.Settings.Filter,
			"ActivationStatus",
			DataCompositionComparisonType.Equal,
			False);		
	SelectionsSetByTeams.Add(NewFilter);
	
EndProcedure

&AtClient
Procedure ShowNotActive(Command)
	
	ClearSelectionsSetByCommands();
	
	NewFilter = CommonClientServer.AddCompositionItem(List.SettingsComposer.Settings.Filter,
			"ActivationStatus",
			DataCompositionComparisonType.Equal,
			True);
	SelectionsSetByTeams.Add(NewFilter);
	
	NewSelectionGroup = CommonClientServer.CreateFilterItemGroup(List.SettingsComposer.Settings.Filter, "FormCommandPanelSelectionsNotValid", DataCompositionFilterItemsGroupType.OrGroup);
	SelectionsSetByTeams.Add(NewSelectionGroup);
	
	CommonClientServer.AddCompositionItem(NewSelectionGroup,
			"ValidityStartDate",
			DataCompositionComparisonType.Greater,
			CurrentDate);

	CommonClientServer.AddCompositionItem(NewSelectionGroup,
			"ValidityEndDate",
			DataCompositionComparisonType.Less,
			CurrentDate);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Balance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkNegatives", True);

	//
	
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Balance.Name);
	Item.Appearance.SetParameterValue("Format", "NFD=2");

	//

 	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ActivationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

		FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("List.ValidityStartDate");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
			ItemFilter.RightValue = New DataCompositionField("CurrentDate");

			ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("List.ValidityStartDate");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

		FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("List.ValidityEndDate");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
			ItemFilter.RightValue = New DataCompositionField("CurrentDate");

			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("List.ValidityEndDate");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);

EndProcedure

&AtClient
Procedure UpdateFormAttributeValues()
	
	CurrentDate = GeneralPurposeTMServerCall.SessionDate();
	
EndProcedure

&AtClient
Procedure ClearSelectionsSetByCommands() 	
	
	SelectionElementsSettings = List.SettingsComposer.Settings.Filter.Items;
	For Each FilterElement In SelectionsSetByTeams Do
		If SelectionElementsSettings.IndexOf(FilterElement.Value)>=0  Then
			SelectionElementsSettings.Delete(FilterElement.Value);
		EndIf;	
	EndDo;
	SelectionsSetByTeams.Clear();
	
EndProcedure

#Region Other

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

#EndRegion
