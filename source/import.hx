// Psych
#if !macro
import Paths;
import flixel.addons.ui.*; //Flixel-UI
import options.OptionsState;

//Stage Objects
import stages.objects.*;
import stages.*;

import shaders.flixel.system.FlxShader;
import haxe.ds.StringMap;

//scripting
#if SCRIPTING_ALLOWED
import scripting.*;
#end

// Extra
#if (hxCodec >= "3.0.0" && VIDEOS_ALLOWED && !ios) import backend.VideoManager; #end //For Better MP4Handler Support
import extras.*; //For CustomSwitchState
import extras.states.*; //Extra States
import extras.substates.*; //Extra Substates

// 0.7x & 1.0 Support
import editors.ChartingStateNew;
import backend.PsychCamera;
import objects.AudioDisplay;
import objects.shape.ShapeEX;
import psychlua.*; //Psych-LUA
import backend.ui.*; //Psych-UI
import mobile.psychlua.Functions;
import objects.Alphabet as AlphabetNew;
import objects.AttachedText as AttachedTextNew;
import backend.animation.PsychAnimationController; //Psych Animation Controller
import backend.BaseStage;
import Song;
import Song.SwagSection;
import Section;
import states.*;

//New Mods System
import backend.Mods;

//New Lua System
#if ACHIEVEMENTS_ALLOWED
import Achievements;
#end

// FlxAnimate
#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

// Desktop
#if desktop
import Discord;
#end

// Mobile Things
#if TOUCH_CONTROLS
import mobile.flixel.*;
import mobile.states.*;
import mobile.objects.*;
import mobile.options.*;
import mobile.backend.*;
import mobile.psychlua.*;
import mobile.substates.*;
import mobile.objects.Hitbox;
import mobile.objects.MobilePad;
import mobile.backend.MobileData;
#else
import mobile.backend.StorageUtil;
import mobile.backend.PsychJNI;
import mobile.options.*;
#end

// Android
#if android
import android.Tools as AndroidTools;
import android.Settings as AndroidSettings;
import android.widget.Toast as AndroidToast;
import android.content.Context as AndroidContext;
import android.Permissions as AndroidPermissions;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Environment as AndroidEnvironment;
import android.os.BatteryManager as AndroidBatteryManager;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
#end

// Lua
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

//Flixel
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.system.FlxSound;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;

import openfl.display3D.textures.RectangleTexture;


//CNE Shit
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxDestroyUtil;
import hxcodec.flixel.FlxVideo;
#end

using StringTools;
