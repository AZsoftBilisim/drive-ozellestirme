

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	CommonClientServer.SetDynamicListParameter(List, "ForEmails_2", NStr("vi = 'Email';
																		|ru = 'Email';
																		|en = 'Email'; fa = 'ایمیل';
																		|it = 'Email';
																		|pl = 'Email';
																		|tr = 'Email'"));
	CommonClientServer.SetDynamicListParameter(List, "ForSMS", NStr("vi = 'SMS';
																	|ru = 'SMS';
																	|en = 'SMS'; fa = 'پیامک';
																	|it = 'SMS';
																	|pl = 'SMS';
																	|tr = 'SMS'"));
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Status", Status, QuickFilterStructure);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Status", Status, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "EmployeeResponsible",
	                                                                        EmployeeResponsible,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleClearing(Item, StandardProcessing)
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "Status",
	                                                                        Status,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        ValueIsFilled(Status));

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

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure SetDraftStatus(Command)
	
	SetStatus("Draft", NStr("vi = 'Bản nháp';
							|ru = 'Черновик';
							|en = 'Draft'; fa = 'پیش‌نویس';
							|it = 'Bozza';
							|pl = 'Draft';
							|tr = 'Taslak'"));
	
EndProcedure

&AtClient
Procedure SetStatusForDispatch(Command)
	
	SetStatus("ForDispatch", NStr("vi = 'Cần gửi';
									|ru = 'К отправке';
									|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
									|it = 'Da inviare';
									|pl = 'Do wysłania';
									|tr = 'Gönderilecek'"));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Procedure SetStatus(StatusName, StatusPresentation)

	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, StatusName);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, HighlightedLinks.Count(), StatusPresentation);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Current date
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UpdateDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UpdateDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Date(1, 1, 1);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không hạn chế>';
													|ru = '<Без ограничений>';
													|en = '<Without limits>'; fa = '<Without limits>';
													|it = '<Senza restrizioni>';
													|pl = '<Bez ograniczeń>';
													|tr = '<Kısıtlamasız>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	
EndProcedure

#EndRegion



