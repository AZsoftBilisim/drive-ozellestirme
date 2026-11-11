
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	ProcedureWhenCreatingReadingOnServer();
	
	If StrFind(Parameters.FieldName, "CWP")>0 Then
		Items.Pages.CurrentPage = Items.Pages.ChildItems.CWP;
	EndIf;
	
	Items.DiscountsMarkups.Visible = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers");
	Items.CWP.Visible           = GetFunctionalOption("UseRetailSales");
	
	If Items.DiscountsMarkups.Visible And Not Items.CWP.Visible Then
		Items.Pages.CurrentPage = Items.DiscountsMarkups;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	If Not Items.DiscountsMarkups.Visible And Items.CWP.Visible Then
		Items.Pages.CurrentPage = Items.CWP;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ProcedureWhenCreatingReadingOnServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_SalesSettingsForUsers", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LimitDiscountAdjustmentsOnChange(Item)
	
	UpdateVisibilityOfManualDiscountRestrictionElements(ThisForm);
	
	If Not Object.LimitDiscountAdjustments Then
		ClearValuesOfDetailsDiscountsMargins();
	EndIf;
	
EndProcedure

&AtClient
Procedure CWP_UseOnChange(Item)
	
	UpdateVisibilityOfCWPElements(ThisForm);
	
	If Not Object.CWP_Use Then
		ClearValuesOfCWPSettingsDetails();
	EndIf;

EndProcedure

&AtClient
Procedure CWP_ReturnOfGoodsOnChange(Item)
	If Not Object.CWP_ReturnOfGoods Then
		Object.CWP_AllowPriceChangesWhenReturningWithoutReceipt = False;
	EndIf;
	UpdateVisibilityOfCWPElements(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UseExceptionsForPriceGroups(Command)
	
	UseExceptionsForPriceGroups = True;
	
	Items.GroupUseExceptionsForPriceGroups.Visible = Not UseExceptionsForPriceGroups;
	Items.GroupDoNotUseExceptionsForPriceGroups.Visible = UseExceptionsForPriceGroups;
	Items.PriceGroups.Visible = UseExceptionsForPriceGroups;
	
EndProcedure

&AtClient
Procedure NotUseExceptionsForPriceGroups(Command)
	
	If Object.PriceGroups.Count() > 0 Then
		QuestionResult = Undefined;

		ShowQueryBox(New CallbackDescription("NotUseExceptionsForPriceGroupsCompletion", ThisObject), NStr("vi = 'Bảng làm rõ sẽ bị xóa, tiếp tục?';
																											|ru = 'Таблица уточнений будет очищена, продолжить?';
																											|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
																											|it = 'La tabella di affinamento verrà ripulita, continuare?';
																											|pl = 'Tabela uściśleń zostanie oczyszczona, kontynuować?';
																											|tr = 'Açıklama tablosu silinecek. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;
	
	DoNotUseExceptionsForFragmentPriceGroups();
EndProcedure

&AtClient
Procedure NotUseExceptionsForPriceGroupsCompletion(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.No Then
        Return;
    EndIf;
    
    DoNotUseExceptionsForFragmentPriceGroups();

EndProcedure

&AtClient
Procedure DoNotUseExceptionsForFragmentPriceGroups()
    
    Object.PriceGroups.Clear();
    
    UseExceptionsForPriceGroups = False;
    
    Items.GroupUseExceptionsForPriceGroups.Visible = Not UseExceptionsForPriceGroups;
    Items.GroupDoNotUseExceptionsForPriceGroups.Visible = UseExceptionsForPriceGroups;
    Items.PriceGroups.Visible = UseExceptionsForPriceGroups;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Procedure UpdateVisibilityOfManualDiscountRestrictionElements(Form)
	
	LimitDiscountAdjustments = Form.Object.LimitDiscountAdjustments;
	
	Form.Items.PercentRateOfManualDiscount.Enabled  = LimitDiscountAdjustments;
	Form.Items.MaximumPercentageForManualMarkup.Enabled = LimitDiscountAdjustments;
	Form.Items.PriceGroups.Enabled = LimitDiscountAdjustments;
	Form.Items.PriceGroups.Enabled = LimitDiscountAdjustments;
	
	Form.Items.GroupDoNotUseExceptionsForPriceGroups.Enabled = LimitDiscountAdjustments;
	Form.Items.GroupUseExceptionsForPriceGroups.Enabled = LimitDiscountAdjustments;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateVisibilityOfCWPElements(Form)
	
	CWP_Use = Form.Object.CWP_Use;
	
	Form.Items.CWP_ReturnOfGoods.Enabled                    	= CWP_Use;
	Form.Items.CWP_CashDeposit.Enabled                    	= CWP_Use;
	Form.Items.CWP_CashWithdrawal.Enabled                      	= CWP_Use;
	Form.Items.RowAdjustment.Enabled               	= CWP_Use;
	Form.Items.CWP_Delay.Enabled                         	= CWP_Use;
	Form.Items.CWP_Reserve.Enabled                  	= CWP_Use;
	Form.Items.CWP_OpenShift.Enabled                     	= CWP_Use;
	Form.Items.CWP_CloseShift.Enabled                     	= CWP_Use;
	Form.Items.CWP_ManualChangeOfLoyaltyCard.Enabled          	= CWP_Use;
	Form.Items.CWP_ChangeLoyaltyCardHolderInformation.Enabled 	= CWP_Use;
	Form.Items.RMK_AllowPaymentWithoutConfirmationFromSBP.Enabled = CWP_Use;
	Form.Items.CWP_AllowPriceChangesWhenReturningWithoutReceipt.Enabled = CWP_Use And Form.Object.CWP_ReturnOfGoods;
	
EndProcedure

&AtServer
Procedure ProcedureWhenCreatingReadingOnServer()
	
	UpdateVisibilityOfManualDiscountRestrictionElements(ThisForm);
	UpdateVisibilityOfCWPElements(ThisForm);
	
	If GetFunctionalOption("UsePriceGroups") Then
		
		UseExceptionsForPriceGroups = Object.PriceGroups.Count() > 0;
		
		Items.GroupUseExceptionsForPriceGroups.Visible = Not UseExceptionsForPriceGroups;
		Items.GroupDoNotUseExceptionsForPriceGroups.Visible = UseExceptionsForPriceGroups;
		Items.PriceGroups.Visible = UseExceptionsForPriceGroups;
		
	Else
		
		UseExceptionsForPriceGroups = False;
		
		Items.GroupDoNotUseExceptionsForPriceGroups.Visible = False;
		Items.GroupUseExceptionsForPriceGroups.Visible = False;
		Items.PriceGroups.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetObjectDetailsValues(ArrayOfObjectDetails, Value)
	
	For Each ObjectAttribute In ArrayOfObjectDetails Do
		Object[ObjectAttribute] = Value;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearValuesOfDetailsDiscountsMargins()
	
	AttributesArray = New Array;
	AttributesArray.Add("MaximumPercentageForManualMarkup");
	AttributesArray.Add("PercentRateOfManualDiscount");

	SetObjectDetailsValues(AttributesArray, False);

	DoNotUseExceptionsForFragmentPriceGroups();
	
EndProcedure

&AtClient
Procedure ClearValuesOfCWPSettingsDetails()

	AttributesArray = New Array;
	AttributesArray.Add("CWP_ReturnOfGoods");
	AttributesArray.Add("CWP_CashDeposit");
	AttributesArray.Add("CWP_CashWithdrawal");
	AttributesArray.Add("RowAdjustment");
	AttributesArray.Add("CWP_Delay");
	AttributesArray.Add("CWP_Reserve");
	AttributesArray.Add("CWP_OpenShift");
	AttributesArray.Add("CWP_CloseShift");
	AttributesArray.Add("CWP_ManualChangeOfLoyaltyCard");
	AttributesArray.Add("CWP_ChangeLoyaltyCardHolderInformation");
	AttributesArray.Add("RMK_AllowPaymentWithoutConfirmationFromSBP");
	AttributesArray.Add("CWP_AllowPriceChangesWhenReturningWithoutReceipt");
	
	SetObjectDetailsValues(AttributesArray, False);
	
EndProcedure

#EndRegion

#EndRegion
