
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// Configuration options are defined only for products.
	OwnerOfOptions = Undefined;
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner", OwnerOfOptions)
		And ValueIsFilled(OwnerOfOptions) Then

		ItemsTypes = Enums.ItemsTypes;
		OwnerType = Common.ObjectAttributeValue(OwnerOfOptions, "ItemsType");
		If OwnerType <> ItemsTypes.OwnGoods
			And OwnerType <> ItemsTypes.ReusablePackage Then
			AutoTitle = False;
			Title = NStr("vi = 'Phương án đóng bộ được sử dụng chỉ đối với hàng hóa';
						|ru = 'Варианты комплектации используются только для товаров';
						|en = 'Kit configurations are used for goods only'; fa = 'Kit configurations are used for goods only';
						|it = 'Le opzioni di configurazione vengono utilizzate solo per le merci';
						|pl = 'Warianty kompletowania są używane tylko dla towarów';
						|tr = 'Toplama seçenekleri yalnızca ürünler için kullanılır'");
			Items.List.ReadOnly = True;
		EndIf;
		
		Items.Owner.Visible = False;
	EndIf;
	
	Items.List.ChoiceMode = (True = Parameters.ChoiceMode);
	Items.List.MultipleChoice = (True = Parameters.MultipleChoice);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "OwnerUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "List.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

EndProcedure

#EndRegion
