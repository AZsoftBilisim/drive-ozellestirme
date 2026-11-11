////////////////////////////////////////////////////////////////////////////////
// Delayed updating of the information base.
// The module contains update handlers for the deferred execution
// of documents by registers.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns parameters for deferred update handlers
//
// Parameters:
//  ParameterId_	 - String - unique identifier for the parameters
//  DefaultValue		 - Arbitrary - the value that will be assigned to the parameters if they are missing.
//
// Returns:
//  Map - Contains parameters of deferred update handlers.
//    
Function UpdateHandlersParameters(ParameterId_, DefaultValue = Undefined) Export

	HandlersParameters = Constants.UpdateHandlersParameters.Get().Get();
	If TypeOf(HandlersParameters) <> Type("Map") Then
		HandlersParameters = New Map;
	EndIf;
	If HandlersParameters.Get(ParameterId_) = Undefined Then
		HandlersParameters.Insert(ParameterId_, DefaultValue);
	EndIf;

	Return HandlersParameters;
	
EndFunction

// Writes information about a delayed update to the update handler Parameter constant.
//
// Parameters:
//  UpdateHandlersParameters	 - Structure - Contains saved parameters in the constant "update handler Parameters"
//  that are required for subsequent processing by the deferred update handler
//  PointInTime					 - PointInTime - The point in time of the document when the deferred update handler finished executing
//  KeyName						 - String		 - Name of the key of the stored value in the "update handler Parameters" structure.
//
Procedure RecordInformationAboutDelayedUpdate(UpdateHandlersParameters, PointInTime, KeyName) Export

	If ValueIsFilled(PointInTime) Then
		UpdateHandlersParameters.Insert(KeyName, PointInTime);
	Else
		UpdateHandlersParameters.Delete(KeyName);
	EndIf;

	ManagerOfConstant = Constants.UpdateHandlersParameters.CreateValueManager();
	ManagerOfConstant.Value = New ValueStorage(UpdateHandlersParameters);
	InfobaseUpdate.WriteData(ManagerOfConstant);

EndProcedure

#EndRegion
