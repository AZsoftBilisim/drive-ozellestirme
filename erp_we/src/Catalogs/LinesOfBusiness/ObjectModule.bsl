
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	If Status.IsEmpty() Then
		Status = Enums.LineOfBusinessStatuses.Used;
	EndIf;
	
	DestinationPattern = Catalogs.LinesOfBusiness.DestinationPattern(ThisObject);
	Catalogs.Assignments.CheckFillBeforeRecording(
		Purpose,
		DestinationPattern,
		ThisObject,
		"CostAccounting",
		Cancel,
		True,
		Not CostAccounting);
	
	AdditionalProperties.Insert("IsNew", IsNew());
	If Not IsNew() Then
		AttributesBeforeRecording = Common.ObjectAttributeValue(Ref,
			"ExcessOfAssignedGoodsAndLaborDemandIsAllowed");
		AdditionalProperties.Insert("UpdateAssignment",
			AttributesBeforeRecording <> ExcessOfAssignedGoodsAndLaborDemandIsAllowed);
	Else
		AdditionalProperties.Insert("UpdateAssignment", Not ExcessOfAssignedGoodsAndLaborDemandIsAllowed);
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
	LinesOfBusinessLocalization.BeforeWrite(ThisObject, Cancel);
	If CostAccounting Then
		FlagUpdateAssignmentBeyondDemandIsAllowedNotRequired = True;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	DestinationPattern = Catalogs.LinesOfBusiness.DestinationPattern(ThisObject);
	TypeOfVATTaxationActivity = VATAccountingERP.TypeOfVATTaxationActivity(VATTaxation);
	Catalogs.Assignments.WhenWritingCatalog(
		Purpose,
		DestinationPattern,
		ThisObject,
		TypeOfVATTaxationActivity,
		AdditionalProperties.UpdateAssignment);
	
	RefreshReusableValues();
	
	// Writing a subordinate constant.
	SupplyServer.UseControlOfMovementOfSeparateGoodsToCalculateAndWrite();
	SupplyServer.UseNonOrderingAssignmentsToCalculateAndWrite();
	
	TMCommonUse.SyncKeys(ThisObject);
	
	LinesOfBusinessLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If VATTaxationIsDeterminedInDocuments Then
		NotCheckedAttributeArray.Add("VATTaxation");
	EndIf;
	
	If ValueIsFilled(EndDateOfActivity)
		And ValueIsFilled(StartDateOfActivity) 
		And EndDateOfActivity < StartDateOfActivity Then
		Common.MessageToUser(
			NStr("vi = 'Ngày cuối kỳ hoạt động theo lĩnh vực phải lớn hơn ngày bắt đầu.';
				|ru = 'Дата окончания периода деятельности по направлению должна быть больше даты начала.';
				|en = 'The end date of the activity period by the line of business must be greater than the start date.'; fa = 'The end date of the activity period by the line of business must be greater than the start date.';
				|it = 'La data di fine periodo di attività per direzione deve essere successiva alla data di inizio.';
				|pl = 'Data zakończenia okresu działalności według rodzaju powinna być większa niż data rozpoczęcia.';
				|tr = 'İş kolu döneminin bitiş tarihi, başlangıç ​​tarihinden büyük olmalıdır.'"), 
			, 
			"Object." + Metadata().Attributes.EndDateOfActivity.Name,
			,
			Cancel);
	EndIf;
	
	If Not StateContractAndSDOContractFulfillment Then
		NotCheckedAttributeArray.Add("StateContract");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	LinesOfBusinessLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If Not IsFolder Then
		Purpose = Catalogs.Assignments.EmptyRef();
		If VATTaxationIsDeterminedInDocuments Then
			VATTaxation = Enums.VATTaxationTypes.EmptyRef();
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.DimensionKeysOfAccountingByPartners", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion
#EndRegion

#EndIf