#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - Structure:
//    * Text                             - String - restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String - restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - to determine automatically.
//                                        - Boolean - if False, then always write access keys,
//                                          if True, then do not write access keys,
//                                          but use the owner's access keys (it is required
//                                          that the restriction be strictly on the owner object).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Manager = "InformationRegister.FiscalTransactions";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndRegion

#Region Internal

Procedure ClearRegisterBeforeDate(ClearDate) Export
	
	SetPrivilegedMode(True);
	
	// APK: 1328-off
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FiscalTransactions.RecordID AS RecordID
		|FROM
		|	InformationRegister.FiscalTransactions AS FiscalTransactions
		|WHERE
		|	FiscalTransactions.Date < &ClearDate";
	
	Query.SetParameter("ClearDate", ClearDate);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.FiscalTransactions.CreateRecordSet();
	Selection      = QueryResult.Select();
	While Selection.Next() Do
		RecordSet.Clear();
		RecordSet.Filter.RecordID.Set(Selection.RecordID);
		RecordSet.Write(True);
	EndDo;
	// APK: 1328-on
	
EndProcedure

Function RecordDataForThoseSupport(IDOfFiscalRecord) Export
	
	
EndFunction


#EndRegion

#EndIf

