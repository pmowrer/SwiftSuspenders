/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders
{
	import flexunit.framework.Assert;

	import org.hamcrest.assertThat;
	import org.hamcrest.core.isA;
	import org.hamcrest.object.equalTo;
	import org.hamcrest.object.hasProperties;
	import org.hamcrest.object.isTrue;
	import org.hamcrest.object.notNullValue;
	import org.swiftsuspenders.injection.dependencyproviders.ClassProvider;
	import org.swiftsuspenders.injection.dependencyproviders.SingletonProvider;
	import org.swiftsuspenders.injection.InjectionMapping;
	import org.swiftsuspenders.injection.Injector;
	import org.swiftsuspenders.injection.InjectorError;
	import org.swiftsuspenders.support.types.Clazz;
	import org.swiftsuspenders.support.types.Interface;
	import org.swiftsuspenders.utils.SsInternal;

	use namespace SsInternal;

	public class InjectionMappingTests
	{
		private var injector:Injector;
		
		[Before]
		public function setup():void
		{
			injector = new Injector();
		}

		[After]
		public function teardown():void
		{
			Injector.SsInternal::purgeInjectionPointsCache();
			injector = null;
		}
		
		[Test]
		public function configIsInstantiated():void
		{
			var config : InjectionMapping = new InjectionMapping(injector, Clazz, '', '');
			
			Assert.assertTrue(config is InjectionMapping);
		}

		[Test]
		public function mappingWithoutProviderEverSetUsesClassProvider() : void
		{
			var config : InjectionMapping = new InjectionMapping(injector, Clazz, '', '');
			assertThat(config.getProvider(), isA(ClassProvider));
		}

		[Test]
		public function injectionMappingAsSingletonMethodCreatesSingletonProvider():void
		{
			var config : InjectionMapping = new InjectionMapping(injector, Clazz, '', '');
			config.asSingleton();
			assertThat(config.getProvider(), isA(SingletonProvider));
		}

		[Test]
		public function sameNamedSingletonIsReturnedOnSecondResponse():void
		{
			const provider : SingletonProvider = new SingletonProvider(Clazz, injector);
			var returnedResponse:Object = provider.apply(null, injector, null);
			var secondResponse:Object = provider.apply(null, injector, null);

			Assert.assertStrictlyEquals( returnedResponse, secondResponse );
		}

		[Test]
		public function setProviderChangesTheProvider():void
		{
			const provider1 : SingletonProvider = new SingletonProvider(Clazz, injector);
			const provider2 : ClassProvider = new ClassProvider(Clazz);
			var config : InjectionMapping = new InjectionMapping(injector, Clazz, '', '');
			config.toProvider(provider1);
			assertThat(config.getProvider(), equalTo(provider1));
			config.toProvider(null);
			config.toProvider(provider2);
			assertThat(config.getProvider(), equalTo(provider2));
		}

		[Test]
		public function sealingAMappingMakesItSealed() : void
		{
			const config : InjectionMapping = new InjectionMapping(injector, Interface, '', '');
			config.seal();
			assertThat(config.isSealed, isTrue());
		}

		[Test]
		public function sealingAMappingMakesItUnchangable() : void
		{
			const config : InjectionMapping = new InjectionMapping(injector, Interface, '', '');
			config.seal();
			const methods : Array = [
				{method : 'asSingleton', args : []},
				{method : 'toSingleton', args : [Clazz]},
				{method : 'toType', args : [Clazz]},
				{method : 'toValue', args : [Clazz]},
				{method : 'toProvider', args : [null]},
				{method : 'local', args : []},
				{method : 'shared', args : []},
				{method : 'soft', args : []},
				{method : 'strong', args : []}];
			const testedMethods : Array = [];
			for each (var method : Object in methods)
			{
				try
				{
					config[method.method].apply(config, method.args);
				}
				catch(error : InjectorError)
				{
					testedMethods.push(method);
				}
			}
			assertThat(testedMethods, hasProperties(methods));
		}

		[Test(expects='org.swiftsuspenders.injection.InjectorError')]
		public function unmappingASealedMappingThrows() : void
		{
			injector.map(Interface).seal();
			injector.unmap(Interface);
		}

		[Test(expects='org.swiftsuspenders.injection.InjectorError')]
		public function doubleSealingAMappingThrows() : void
		{
			injector.map(Interface).seal();
			injector.map(Interface).seal();
		}

		[Test]
		public function sealReturnsAnUnsealingKeyObject() : void
		{
			const config : InjectionMapping = new InjectionMapping(injector, Interface, '', '');
			assertThat(config.seal(), notNullValue());
		}

		[Test(expects='org.swiftsuspenders.injection.InjectorError')]
		public function unsealingAMappingWithoutKeyThrows() : void
		{
			injector.map(Interface).seal();
			injector.map(Interface).unseal(null);
		}

		[Test(expects='org.swiftsuspenders.injection.InjectorError')]
		public function unsealingAMappingWithWrongKeyThrows() : void
		{
			injector.map(Interface).seal();
			injector.map(Interface).unseal({});
		}

		[Test]
		public function unsealingAMappingWithRightKeyMakesItChangable() : void
		{
			const key : Object = injector.map(Interface).seal();
			injector.map(Interface).unseal(key);
			injector.map(Interface).local();
		}

		[Test]
		public function valueMappingSupportsNullValue() : void
		{
			injector.map(Interface).toValue(null);
			injector.getInstance(Interface);
		}
	}
}