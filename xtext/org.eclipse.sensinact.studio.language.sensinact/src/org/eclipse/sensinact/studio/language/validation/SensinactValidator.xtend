/**
 * Copyright (c) 2018 CEA.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 *  Contributors:
 *     CEA - initial API and implementation and/or initial documentation
 */
/*
 * generated by Xtext 2.9.1
 */
package org.eclipse.sensinact.studio.language.validation

import org.eclipse.sensinact.studio.language.sensinact.DSL_CEP_AFTER
import org.eclipse.sensinact.studio.language.sensinact.DSL_CEP_BEFORE
import org.eclipse.sensinact.studio.language.sensinact.DSL_CEP_DURATION
import org.eclipse.sensinact.studio.language.sensinact.DSL_CEP_DURATION_MIN
import org.eclipse.sensinact.studio.language.sensinact.DSL_CEP_DURATION_SEC
import org.eclipse.sensinact.studio.language.sensinact.DSL_CEP_STATEMENT
import org.eclipse.sensinact.studio.language.sensinact.DSL_ListParam
import org.eclipse.sensinact.studio.language.sensinact.DSL_REF
import org.eclipse.sensinact.studio.language.sensinact.DSL_Resource
import org.eclipse.sensinact.studio.language.sensinact.DSL_ResourceAction
import org.eclipse.sensinact.studio.language.sensinact.DSL_SENSINACT
import org.eclipse.sensinact.studio.language.sensinact.SensinactPackage
import org.eclipse.sensinact.studio.model.manager.modelupdater.ModelEditor
import org.eclipse.sensinact.studio.resource.AccessMethodType
import java.math.BigDecimal
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.validation.Check
import org.eclipse.sensinact.studio.model.resource.utils.ResourceDescriptor
import org.eclipse.sensinact.studio.language.sensinact.impl.DSL_REFImpl

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class SensinactValidator extends AbstractSensinactValidator {
	
	def isConnected() {
		return ModelEditor.getInstance().getGatewaysId.length != 0;
	}

	@Check
	def checkGatewayIsConnected(DSL_SENSINACT eca) {
		if (!isConnected())
			warning("Please connect the studio to your gateway", SensinactPackage.Literals.DSL_SENSINACT__RESOURCES);
	}

	@Check
	def void refNameIsUnique(DSL_REF ref) {
		var nameOccurences = 0;
		var name = ref.getName();

		var superEntity = (ref.eContainer() as DSL_SENSINACT);
		if (superEntity !== null) {
			for (other : superEntity.resources) {
				if (name.equals(other.getName())) {
					nameOccurences++;
				}
			}
			for (other : superEntity.cep) {
				if (name.equals(other.getName())) {
					nameOccurences++;
				}
			}

			if (nameOccurences > 1) {
				error("Reference names names have to be unique", SensinactPackage.Literals.DSL_REF__NAME, ref.getName());
			}
		}
	}

	@Check
	def checkResourceExists(DSL_Resource dslResource) {
		if (isConnected()) {
			var gatewayID = dslResource.gatewayID;
			var deviceID = dslResource.deviceID;
			var serviceID = dslResource.serviceID;
			var resourceID = dslResource.resourceID;

			if (! ModelEditor.getInstance().existsGateway(gatewayID)) {
				warning("The gateway " + gatewayID + " does not exist",
					SensinactPackage.Literals.DSL_RESOURCE__GATEWAY_ID, 'INVALID_NAME');
			} else if (! ModelEditor.getInstance().existsDevice(gatewayID, deviceID)) {
				warning("The device " + deviceID + " does not exist in gateway " + gatewayID,
					SensinactPackage.Literals.DSL_RESOURCE__DEVICE_ID, 'INVALID_NAME');
			} else if (! ModelEditor.getInstance().existsService(gatewayID, deviceID, serviceID)) {
				warning("The service " + serviceID + " does not exist in gateway " + gatewayID,
						SensinactPackage.Literals.DSL_RESOURCE__SERVICE_ID, 'INVALID_NAME');
			} else if (! ModelEditor.getInstance().existsResource(gatewayID, deviceID, serviceID, resourceID)) {
				warning("The resource " + resourceID + " does not exist in gateway " + gatewayID,
						SensinactPackage.Literals.DSL_RESOURCE__RESOURCE_ID, 'INVALID_NAME');
			}
		}
	}

	@Check
	def checkActionAccessMethod(DSL_ResourceAction resourceAction) {
		if (isConnected()) {
			var ref = resourceAction.ref;
			var AccessMethodType actionType = AccessMethodType.getByName(resourceAction.actiontype);
			var nbParams = getNbParams(resourceAction.listParam);
			checkParameters(ref, actionType, nbParams, SensinactPackage.Literals.DSL_RESOURCE_ACTION__ACTIONTYPE);
		}
	}

	def getNbParams(DSL_ListParam params) {
		if (params === null)
			return 0;
		if (params.param === null)
			return 0;
		return params.param.size;
	}

	def checkParameters(DSL_REF ref, AccessMethodType actionType, int nbParams, EStructuralFeature feature) {
		if (ref instanceof DSL_Resource) {

			var dslResource = ref as DSL_Resource;

			var gatewayID = dslResource.gatewayID;
			var deviceID = dslResource.deviceID;
			var serviceID = dslResource.serviceID;
			var resourceID = dslResource.resourceID;

			var descriptor = new ResourceDescriptor(gatewayID, deviceID, serviceID, resourceID);


			// finding method
			if (descriptor !== null && actionType !== null) {
				var method = ModelEditor.getInstance().getAccessMethodWithTypeNbParams(descriptor, actionType, nbParams);
												
				if (method === null) {
					var String msg = null;
					if (nbParams == 0) {
						msg = "This action type without parameters is not available for this resource";
					} else if (nbParams == 1) {
						msg = "This action type with one parameter is not available for this resource";
					} else if (nbParams == 0) {
						msg = "This action type with " + nbParams + " parameters is not available for this resource";
					}
					error(msg, feature);
				}
			}

		} else if (ref instanceof DSL_CEP_STATEMENT) {
			// no check
		} else if (ref.class.equals(typeof(DSL_REFImpl))) {
			// exact same class (no subclassing)
		} else {
			throw new RuntimeException("Should never happen");
		}
	}

	@Check
	def checkCepAfter(DSL_CEP_AFTER operation) {
		var start = timestamp(operation.start);
		var end = timestamp(operation.end);

		if (start.compareTo(end) >= 0) {
			var msg = "end must be after start";
			error(msg, SensinactPackage.Literals.DSL_CEP_AFTER__END);
		}
	}

	@Check
	def checkCepBefore(DSL_CEP_BEFORE operation) {
		var start = timestamp(operation.start);
		var end = timestamp(operation.end);

		if (start.compareTo(end) >= 0) {
			var msg = "end must be after start";
			error(msg, SensinactPackage.Literals.DSL_CEP_BEFORE__END);
		}
	}

	def timestamp(DSL_CEP_DURATION duration) {
		var retval = BigDecimal.ZERO;
		if (duration !== null && duration.units !== null) {
			for (unit : duration.units) {
				if (unit instanceof DSL_CEP_DURATION_MIN) {
					var min = unit as DSL_CEP_DURATION_MIN;
					retval = retval.add(min.min.multiply(new BigDecimal("60")));
				} else if (unit instanceof DSL_CEP_DURATION_SEC) {
					var sec = unit as DSL_CEP_DURATION_SEC;
					retval = retval.add(sec.sec);
				}
			}
		}
		return retval;
	}
	
}
